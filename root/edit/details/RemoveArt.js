/*
 * @flow strict
 * Copyright (C) 2020 MetaBrainz Foundation
 *
 * This file is part of MusicBrainz, the open internet music database,
 * and is licensed under the GPL version 2, or (at your option) any
 * later version: http://www.gnu.org/licenses/gpl-2.0.txt
 */

import DescriptiveLink
  from '../../static/scripts/common/components/DescriptiveLink.js';
import {commaOnlyListText}
  from '../../static/scripts/common/i18n/commaOnlyList.js';
import EditArtwork from '../components/EditArtwork.js';

component RemoveArt(
  archiveName: 'cover' | 'event',
  edit:
    | RemoveCoverArtEditT
    | RemoveEventArtEditT,
  entityType: 'event' | 'release',
  formattedEntityType: string,
) {
  const display = edit.display_data;

  return (
    <table className={'details remove-' + archiveName + '-art'}>
      <tr>
        <th>{addColonText(formattedEntityType)}</th>
        <td>
          {/* $FlowFixMe[prop-missing] */}
          <DescriptiveLink entity={display[entityType]} />
        </td>
      </tr>

      <tr>
        <th>{l('Types:')}</th>
        <td>
          {display.artwork.types?.length ? (
            commaOnlyListText(display.artwork.types.map(
              type => lp_attributes(type, archiveName + '_art_type'),
            ))
          ) : lp('(none)', 'type')}
        </td>
      </tr>

      {nonEmpty(display.artwork.filename) ? (
        <tr>
          <th>{addColonText(l('Filename'))}</th>
          <td>
            <code>
              {display.artwork.filename}
            </code>
          </td>
        </tr>
      ) : null}

      {display.artwork.comment ? (
        <tr>
          <th>{addColonText(l('Comment'))}</th>
          <td>{display.artwork.comment}</td>
        </tr>
      ) : null}

      <EditArtwork
        artwork={display.artwork}
        // $FlowFixMe[prop-missing]
        entity={display[entityType]}
      />
    </table>
  );
}

export default RemoveArt;
