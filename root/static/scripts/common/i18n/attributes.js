/*
 * @flow
 * Copyright (C) 2018 MetaBrainz Foundation
 *
 * This file is part of MusicBrainz, the open internet music database,
 * and is licensed under the GPL version 2, or (at your option) any
 * later version: http://www.gnu.org/licenses/gpl-2.0.txt
 */

import * as wrapGettext from './wrapGettext';

export const l_attributes = wrapGettext.dgettext('attributes');
export const ln_attributes = wrapGettext.dngettext('attributes');
export const lp_attributes = wrapGettext.dpgettext('attributes');

export const N_lp_attributes = (key: string, context: string) => (
  () => lp_attributes(key, context)
);
