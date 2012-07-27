/*
   This file is part of MusicBrainz, the open internet music database.
   Copyright (C) 2012 MetaBrainz Foundation

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
*/

(function() {

var Entity, Source, Artist, Label, Recording, Work, URL, entities, mapping, cache = {};

mapping = {
    copy:    ["type", "gid", "id", "artistCredit", "number", "position", "length"],
    ignore:  ["refcount", "relationships", "artist", "artists", "label", "value", "isrcs", "artist_credit"],
    include: ["type", "gid", "id", "name", "sortname", "newWork", "comment", "work_type", "work_language"]
};

// represents a core entitiy, either existing or newly-created.
// Entity is private - modules use RE.Entity to find or create an entity.

Entity = function() {};

Entity.prototype.init = function() {
    this.refcount = 0;
    this.name = ko.observable("");

    this.rendering = ko.computed({
        read: function() {
            return this.render(this.name());
        },
        owner: this,
        deferEvaluation: true
    });
};

Entity.prototype.render = function(name, options) {
    options = $.extend({
        href: "/" + this.type + "/" + this.gid, target: "_blank",
    }, options);
    return MB.html.a(options, name);
};

Entity.prototype.remove = function() {
    if (--this.refcount == 0) {
        delete cache[this.gid];
        delete RE.newWorks[this.gid];
    }
};

Source = function() {};

Source.prototype = new Entity;

Source.prototype.init = function() {
    Entity.prototype.init.call(this);
    this.relationships = ko.observableArray([]);
};

// searches this entity's relationships for potential duplicate "rel"
// if it is a duplicate, remove and merge it

Source.prototype.mergeRelationship = function(rel) {
    var relationships = this.relationships(), obj = ko.mapping.toJS(rel);
    delete obj.id;

    // XXX figure out a faster/nicer way to merge relationship attributes
    var attrs = $.extend({}, obj.attributes),
        attrNames = MB.utility.keys(obj.attributes), name, value;

    for (var i = 0; i < relationships.length; i++) {
        var other = relationships[i];

        if (rel !== other && rel.isDuplicate(other)) {

            obj.attributes = {};
            for (var i = 0; name = attrNames[i]; i++) {
                value = obj.attributes[name] = attrs[name];

                if (!value || ($.isArray(value) && !value.length))
                    obj.attributes[name] = other.attributes.peek()[name].peek();
            }
            ko.mapping.fromJS(obj, other);
            rel.remove();
            return true;
        }
    }
    return false;
};

Artist = function() {
    this.init();
    this.sortname = ko.observable("");

    this.rendering = ko.computed({
        read: function() {
            return this.render(this.name(), {title: this.sortname()});
        },
        owner: this,
        deferEvaluation: true
    });
};

Label = function() {
    this.init();
};

Recording = function() {
    this.init();
    this.performanceRelationships = ko.observableArray([]);
};

Release = function() {
    this.init();
};

Work = function() {
    this.init();
    this.performanceRefcount = 0;
    this.comment = ko.observable("");
    this.work_type = ko.observable(null);
    this.work_language = ko.observable(null);

    this.rendering = ko.computed({
        read: function() {
            return RE.Util.isMBID(this.gid) ? this.render(this.name()) : this.name();
        },
        owner: this,
        deferEvaluation: true
    });
};

URL = function() {
    this.init();

    this.rendering = ko.computed({
        read: function() {
            var name = this.name();
            if (name.length > 50) name = name.slice(0, 50) + "...";
            return this.render(name);
        },
        owner: this,
        deferEvaluation: true
    });
};

Artist.prototype = new Entity;
Label.prototype = new Entity;
Recording.prototype = new Source;
Release.prototype = new Source;
Work.prototype = new Source;
URL.prototype = new Entity;

entities = {
    artist:    Artist,
    label:     Label,
    recording: Recording,
    release:   Release,
    work:      Work,
    url:       URL
};

RE.Entity = function(obj) {
    if (obj instanceof Entity) return obj;
    var ent;
    if ((ent = cache[obj.gid]) === undefined) {
        ent = cache[obj.gid] = new entities[obj.type];

        if (obj.type == "work" && !RE.Util.isMBID(obj.gid))
            RE.newWorks[obj.gid] = ent;
    }
    ko.mapping.fromJS(obj, mapping, ent);
    return ent;
};

RE.Entity.isInstance = function(obj) {
    return obj instanceof Entity;
};

})();
