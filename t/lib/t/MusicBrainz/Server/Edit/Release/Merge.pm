package t::MusicBrainz::Server::Edit::Release::Merge;
use Test::Routine;
use Test::More;

with 't::Context';

BEGIN { use MusicBrainz::Server::Edit::Release::Merge };

use MusicBrainz::Server::Context;
use MusicBrainz::Server::Constants qw( $EDIT_RELEASE_MERGE $STATUS_APPLIED );
use MusicBrainz::Server::Data::Release;
use MusicBrainz::Server::Test qw( accept_edit reject_edit );

test all => sub {

    my $test = shift;
    my $c = $test->c;

    MusicBrainz::Server::Test->prepare_test_database($c, '+release');

    my $edit = $c->model('Edit')->create(
        edit_type => $EDIT_RELEASE_MERGE,
        editor_id => 1,
        new_entity => {
            id => 6,
            name => 'Release 1',
        },
        old_entities => [
            {
                id => 7,
                name => 'Release 2'
            }
        ],
        merge_strategy => $MusicBrainz::Server::Data::Release::MERGE_APPEND,
        medium_changes => [
            {
                release => {
                    id => 6,
                    name => 'Release 1',
                },
                mediums => [
                    {
                        id => 2,
                        old_position => 1,
                        new_position => 1,
                        old_name => '',
                        new_name => '',
                    },
                ]
            },
            {
                release => {
                    id => 7,
                    name => 'Release 2',
                },
                mediums => [
                    {
                        id => 3,
                        old_position => 1,
                        new_position => 2,
                        old_name => '',
                        new_name => '',
                    },
                ]
            }
        ]
    );

    ok($c->model('Release')->get_by_id(6));
    ok($c->model('Release')->get_by_id(7));

    $edit = $c->model('Edit')->get_by_id($edit->id);
    accept_edit($c, $edit);

    ok($c->model('Release')->get_by_id(6));
    ok(!$c->model('Release')->get_by_id(7));

    $edit = $c->model('Edit')->create(
        edit_type => $EDIT_RELEASE_MERGE,
        editor_id => 1,
        new_entity => {
            id => 6,
            name => 'Release 1',
        },
        old_entities => [
            {
                id => 8,
                name => 'Release 2'
            }
        ],
        merge_strategy => $MusicBrainz::Server::Data::Release::MERGE_APPEND,
        medium_changes => [
            {
                release => {
                    id => 6,
                    name => 'Release 1',
                },
                mediums => [
                    {
                        id => 2,
                        old_position => 1,
                        new_position => 1,
                        old_name => '',
                        new_name => '',
                    },
                    {
                        id => 3,
                        old_position => 2,
                        new_position => 2,
                        old_name => '',
                        new_name => '',
                    },
                ]
            },
            {
                release => {
                    id => 8,
                    name => 'Release 2',
                },
                mediums => [
                    {
                        id => 4,
                        old_position => 1,
                        new_position => 3,
                        old_name => '',
                        new_name => '',
                    },
                ]
            }
        ]
    );

    accept_edit($c, $edit);
};

test 'Linking Merge Release edits to recordings' => sub {

    my $test = shift;
    my $c = $test->c;

    MusicBrainz::Server::Test->prepare_test_database($c, '+release');

    my $edit = $c->model('Edit')->create(
        edit_type => $EDIT_RELEASE_MERGE,
        editor_id => 1,
        new_entity => {
            id => 6,
            name => 'Release 1',
        },
        old_entities => [
            {
                id => 7,
                name => 'Release 2'
            }
        ],
        merge_strategy => $MusicBrainz::Server::Data::Release::MERGE_MERGE
    );

    # Use a set because the order can be different, but the elements should be the same.
    use Set::Scalar;
    is(Set::Scalar->new(2, 3)->compare(Set::Scalar->new(@{ $edit->related_entities->{recording} })), 'equal', "Related recordings are correct");

    $edit = $c->model('Edit')->create(
        edit_type => $EDIT_RELEASE_MERGE,
        editor_id => 1,
        new_entity => {
            id => 6,
            name => 'Release 1',
        },
        old_entities => [
            {
                id => 7,
                name => 'Release 2'
            }
        ],
        merge_strategy => $MusicBrainz::Server::Data::Release::MERGE_APPEND,
        medium_changes => [
            {
                release => {
                    id => 6,
                    name => 'Release 1',
                },
                mediums => [
                    {
                        id => 2,
                        old_position => 1,
                        new_position => 1,
                        old_name => '',
                        new_name => '',
                    },
                ]
            },
            {
                release => {
                    id => 7,
                    name => 'Release 2',
                },
                mediums => [
                    {
                        id => 3,
                        old_position => 1,
                        new_position => 2,
                        old_name => '',
                        new_name => '',
                    },
                ]
            }
        ]
    );

    is_deeply([], $edit->related_entities->{recording}, 'empty related recordings for MERGE_APPEND');
};

test 'Old medium and tracks are removed during merge' => sub {

    my $test = shift;
    my $c = $test->c;

    MusicBrainz::Server::Test->prepare_test_database($c, '+release');

    my $edit = $c->model('Edit')->create(
        edit_type => $EDIT_RELEASE_MERGE,
        editor_id => 1,
        new_entity =>     { id => 6, name => 'Release 1' },
        old_entities => [ { id => 7, name => 'Release 2' } ],
        merge_strategy => $MusicBrainz::Server::Data::Release::MERGE_MERGE
    );

    $edit->accept();

    my $release = $c->model('Release')->get_by_gid('7a906020-72db-11de-8a39-0800200c9a71');
    $c->model('Medium')->load_for_releases($release);
    $c->model('Track')->load_for_mediums($release->all_mediums);

    is($release->name, "The Prologue (disc 1)", "Release has expected name after merge");
    is($release->combined_track_count, 1, "Release has 1 track");
    is($release->mediums->[0]->tracks->[0]->gid, 'd6de1f70-4a29-4cce-a35b-aa2b56265583', "Track has expected mbid");

    my $medium = $c->model('Medium')->get_by_id(3);
    is($medium, undef, "Old medium no longer exists");

    my $track_by_mbid = $c->model('Track')->get_by_gid('929e5fb9-cfe7-4764-b3f6-80e056f0c1da');
    isnt($track_by_mbid, undef, 'track by old MBID still fetches something');
    is($track_by_mbid->gid, 'd6de1f70-4a29-4cce-a35b-aa2b56265583', 'Track mbid was redirected');

    my $track = $c->model('Track')->get_by_id(3);
    is($track, undef, "Old track no longer exists");
};

test 'Relationships used as documentation examples are merged (MBS-8516)' => sub {
    my $test = shift;
    my $c = $test->c;

    MusicBrainz::Server::Test->prepare_test_database($c, '+release');
    MusicBrainz::Server::Test->prepare_test_database($c, <<'EOSQL');
INSERT INTO url (id, gid, url) VALUES
    (1, '4ced912c-11a5-4d7d-b280-b5adf30d81b3', 'http://en.wikipedia.org/wiki/Release');

INSERT INTO link_type (id, gid, entity_type0, entity_type1, name, link_phrase, reverse_link_phrase, long_link_phrase)
    VALUES (1, '20452f6b-31c4-43de-b62f-3b3cba9a3a79', 'release', 'url', 'LT1', 'LT1', 'LT1', 'LT1'),
           (2, '2efc4333-09bd-4b7a-9dcd-ff88067063f3', 'release', 'url', 'LT2', 'LT2', 'LT2', 'LT2');

INSERT INTO link (id, link_type, attribute_count, begin_date_year)
    VALUES (1, 1, 0, NULL), (2, 2, 0, NULL), (3, 2, 0, '1966');

-- Exact duplicates where both are used as an example.
INSERT INTO l_release_url (id, link, entity0, entity1) VALUES (1, 1, 6, 1), (2, 1, 7, 1);

-- Quasi-duplicates where the relationship on the merge target has a date, and
-- the relationship on the merge source does not; the latter is used as an example.
-- The example should be updated to use the dated relationship on the target.
INSERT INTO l_release_url (id, link, entity0, entity1) VALUES (3, 2, 7, 1), (4, 3, 6, 1);

INSERT INTO documentation.l_release_url_example (id, published, name)
    VALUES (1, TRUE, 'E1'), (2, TRUE, 'E2'), (3, TRUE, 'E3');
EOSQL

    my $edit = $c->model('Edit')->create(
        edit_type => $EDIT_RELEASE_MERGE,
        editor_id => 1,
        new_entity => { id => 6, name => 'Release 1' },
        old_entities => [{ id => 7, name => 'Release 2' }],
        merge_strategy => $MusicBrainz::Server::Data::Release::MERGE_MERGE,
    );

    $c->model('Edit')->accept($edit);
    is($edit->status, $STATUS_APPLIED);

    my $examples = $c->sql->select_single_column_array(
        'SELECT id FROM documentation.l_release_url_example ORDER BY id'
    );
    is_deeply($examples, [1, 4]);
};

1;
