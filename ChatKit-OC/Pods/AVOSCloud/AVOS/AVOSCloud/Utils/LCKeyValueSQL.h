//
//  LCKeyValueSQL.h
//  AVOS
//
//  Created by Tang Tianyong on 6/26/15.
//  Copyright (c) 2015 LeanCloud Inc. All rights reserved.
//

#ifndef AVOS_LCKeyValueSQL_h
#define AVOS_LCKeyValueSQL_h

#define LC_TABLE_KEY_VALUE @"key_value_table"
#define LC_FIELD_KEY       @"key"
#define LC_FIELD_VALUE     @"value"

#define LC_SQL_CREATE_KEY_VALUE_TABLE_FMT  \
    @"CREATE TABLE IF NOT EXISTS %@ ("     \
        LC_FIELD_KEY   @" TEXT, "          \
        LC_FIELD_VALUE @" BLOB, "          \
        @"PRIMARY KEY(" LC_FIELD_KEY @")"  \
    @")"

#define LC_SQL_SELECT_KEY_VALUE_FMT  \
    @"SELECT * FROM %@ WHERE " LC_FIELD_KEY @" = ?"

#define LC_SQL_UPDATE_KEY_VALUE_FMT               \
    @"INSERT OR REPLACE INTO %@ "                 \
    @"(" LC_FIELD_KEY @", " LC_FIELD_VALUE @") "  \
    @"VALUES(?, ?)"

#define LC_SQL_DELETE_KEY_VALUE_FMT  \
    @"DELETE FROM %@ WHERE " LC_FIELD_KEY @" = ?"

#endif
