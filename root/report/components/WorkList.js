/*
 * @flow strict
 * Copyright (C) 2018 MetaBrainz Foundation
 *
 * This file is part of MusicBrainz, the open internet music database,
 * and is licensed under the GPL version 2, or (at your option) any
 * later version: http://www.gnu.org/licenses/gpl-2.0.txt
 */

import * as React from 'react';
import type {ColumnOptionsNoValue} from 'react-table';

import PaginatedResults from '../../components/PaginatedResults.js';
import useTable from '../../hooks/useTable.js';
import manifest from '../../static/manifest.mjs';
import {
  defineArtistRolesColumn,
  defineEntityColumn,
  defineTextColumn,
} from '../../utility/tableColumns.js';

component WorkList<D: {+work: ?WorkT, ...}>(
  columnsAfter?: $ReadOnlyArray<ColumnOptionsNoValue<D>>,
  columnsBefore?: $ReadOnlyArray<ColumnOptionsNoValue<D>>,
  items: $ReadOnlyArray<D>,
  pager: PagerT,
) {
  const existingWorkItems = items.reduce((
    result: Array<D>,
    item,
  ) => {
    if (item.work != null) {
      result.push(item);
    }
    return result;
  }, []);

  const columns = React.useMemo(
    () => {
      const nameColumn = defineEntityColumn<D>({
        columnName: 'work',
        getEntity: result => result.work ?? null,
        title: l('Work'),
      });
      const authorsColumn = defineArtistRolesColumn<D>({
        columnName: 'authors',
        getRoles: result => result.work?.authors ?? [],
        title: l('Authors'),
      });
      const typeColumn = defineTextColumn<D>({
        columnName: 'type',
        getText: result => {
          const typeName = result.work?.typeName;
          return (nonEmpty(typeName)
            ? lp_attributes(typeName, 'work_type')
            : lp('Unknown', 'type')
          );
        },
        title: l('Type'),
      });

      return [
        ...(columnsBefore ? [...columnsBefore] : []),
        nameColumn,
        authorsColumn,
        typeColumn,
        ...(columnsAfter ? [...columnsAfter] : []),
      ];
    },
    [columnsAfter, columnsBefore],
  );

  const table = useTable<D>({columns, data: existingWorkItems});

  return (
    <PaginatedResults pager={pager}>
      {table}
      {manifest('common/components/ArtistRoles', {async: true})}
    </PaginatedResults>
  );
}

export default WorkList;
