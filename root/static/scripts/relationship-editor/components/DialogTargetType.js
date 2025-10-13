/*
 * @flow strict
 * Copyright (C) 2022 MetaBrainz Foundation
 *
 * This file is part of MusicBrainz, the open internet music database,
 * and is licensed under the GPL version 2, or (at your option) any
 * later version: http://www.gnu.org/licenses/gpl-2.0.txt
 */

import * as React from 'react';

import formatEntityTypeName
  from '../../common/utility/formatEntityTypeName.js';
import type {TargetTypeOptionsT} from '../types.js';
import type {
  DialogActionT,
} from '../types/actions.js';

component _DialogTargetType(
  dispatch: (DialogActionT) => void,
  initialFocusRef?: {-current: HTMLElement | null},
  options: ?TargetTypeOptionsT,
  source: RelatableEntityT,
  targetType: RelatableEntityTypeT,
) {
  function handleTargetTypeChange(event: SyntheticEvent<HTMLSelectElement>) {
    dispatch({
      source,
      // $FlowFixMe[unclear-type]
      targetType: (event.currentTarget.value: any),
      type: 'update-target-type',
    });
  }

  return (
    <tr>
      <td className="required section">
        {l('Related type')}
      </td>
      <td className="fields">
        {options == null ? (
          formatEntityTypeName(targetType)
        ) : (
          <select
            className="entity-type"
            onChange={handleTargetTypeChange}
            ref={initialFocusRef}
            value={targetType}
          >
            {options.map((option) => (
              <option key={option.value} value={option.value}>
                {option.text}
              </option>
            ))}
          </select>
        )}
      </td>
    </tr>
  );
}

const DialogTargetType:
  component(...React.PropsOf<_DialogTargetType>) =
  React.memo(_DialogTargetType);

export default DialogTargetType;
