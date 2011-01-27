package MusicBrainz::Server::Data::EditNote;
use Moose;

use List::MoreUtils qw( uniq );
use MusicBrainz::Server::Entity::EditNote;
use MusicBrainz::Server::Email;
use MusicBrainz::Server::Data::Utils qw(
    placeholders
    query_to_list
);

extends 'MusicBrainz::Server::Data::Entity';

sub _table
{
    return 'edit_note';
}

sub _columns
{
    return 'id, editor, edit, text, post_time';
}

sub sql { shift->c->raw_sql }

sub _column_mapping
{
    return {
        id => 'id',
        editor_id => 'editor',
        edit_id => 'edit',
        text => 'text',
        post_time => 'post_time',
    }
}

sub _entity_class
{
    return 'MusicBrainz::Server::Entity::EditNote';
}

sub load_for_edits
{
    my ($self, @edits) = @_;
    my %id_to_edit = map { $_->id => $_ } @edits;
    my @ids = keys %id_to_edit or return;
    my $query = 'SELECT ' . $self->_columns .
                ' FROM ' . $self->_table .
                ' WHERE edit IN (' . placeholders(@ids) . ')' .
                ' ORDER BY post_time, id';
    my @notes = query_to_list($self->c->raw_sql, sub {
            my $r = shift;
            my $note = $self->_new_from_row($r);
            my $edit = $id_to_edit{ $r->{edit} };
            $note->edit($edit);
            $edit->add_edit_note($note);
            return $note;
        }, $query, @ids);
}

sub insert
{
    my ($self, $edit_id, $note_hash) = @_;
    my $mapping = $self->_column_mapping;
    my %r = map {
        my $key = $mapping->{$_} || $_;
        $key => $note_hash->{$_};
    } keys %$note_hash;
    $r{edit} = $edit_id;
    my $sql = Sql->new($self->c->raw_dbh);
    $self->sql->auto_commit;
    $self->sql->insert_row('edit_note', \%r);
}

sub add_note
{
    my ($self, $edit_id, $note_hash) = @_;
    $self->insert($edit_id, $note_hash);

    my $email_data = MusicBrainz::Server::Email->new( c => $self->c );
    my $edit = $self->c->model('Edit')->get_by_id($edit_id) or die "Edit $edit_id does not exist!";
    $self->c->model('EditNote')->load_for_edits($edit);
    $self->c->model('Vote')->load_for_edits($edit);
    my $editors = $self->c->model('Editor')->get_by_ids($edit->editor_id,
        $note_hash->{editor_id},
        (map { $_->editor_id } @{ $edit->votes }),
        (map { $_->editor_id } @{ $edit->edit_notes }));
    $self->c->model('Editor')->load_preferences(values %$editors);

    my @to_email = grep { $_ != $note_hash->{editor_id} }
        map { $_->id } grep { $_->preferences->email_on_notes }
        map { $editors->{$_->editor_id} }
            @{ $edit->edit_notes },
            @{ $edit->votes },
            $edit;

    my $from = $editors->{ $note_hash->{editor_id} };
    for my $editor_id (uniq @to_email) {
        my $editor = $editors->{ $editor_id };
        $email_data->send_edit_note(
            from_editor => $from,
            editor => $editor,
            note_text => $note_hash->{text},
            edit_id => $edit_id,
            own_edit => $edit->editor_id == $editor->id);
    }
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;

=head1 COPYRIGHT

Copyright (C) 2009 Oliver Charles

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

=cut
