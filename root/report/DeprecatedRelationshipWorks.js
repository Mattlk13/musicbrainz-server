/*
 * @flow strict-local
 * Copyright (C) 2018 MetaBrainz Foundation
 *
 * This file is part of MusicBrainz, the open internet music database,
 * and is licensed under the GPL version 2, or (at your option) any
 * later version: http://www.gnu.org/licenses/gpl-2.0.txt
 */

import * as React from 'react';

import WorkRelationshipList from './components/WorkRelationshipList';
import ReportLayout from './components/ReportLayout';
import type {ReportDataT, ReportWorkRelationshipT} from './types';

const DeprecatedRelationshipWorks = ({
  $c,
  canBeFiltered,
  filtered,
  generated,
  items,
  pager,
}: ReportDataT<ReportWorkRelationshipT>):
React.Element<typeof ReportLayout> => (
  <ReportLayout
    $c={$c}
    canBeFiltered={canBeFiltered}
    description={l(
      `This report lists works which have relationships using
       deprecated and grouping-only relationship types.`,
    )}
    entityType="work"
    filtered={filtered}
    generated={generated}
    title={l('Works with deprecated relationships')}
    totalEntries={pager.total_entries}
  >
    <WorkRelationshipList items={items} pager={pager} />
  </ReportLayout>
);

export default DeprecatedRelationshipWorks;
