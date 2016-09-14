//
//  LCIMMessageCacheSQL.h
//  AVOS
//
//  Created by Tang Tianyong on 5/12/15.
//  Copyright (c) 2015 LeanCloud Inc. All rights reserved.
//

#ifndef AVOS_LCIMMessageCacheSQL_h
#define AVOS_LCIMMessageCacheSQL_h

#define LCIM_TABLE_MESSAGE              @"message"

#define LCIM_FIELD_MESSAGE_ID           @"message_id"
#define LCIM_FIELD_CONVERSATION_ID      @"conversation_id"
#define LCIM_FIELD_FROM_PEER_ID         @"from_peer_id"
#define LCIM_FIELD_TIMESTAMP            @"timestamp"
#define LCIM_FIELD_RECEIPT_TIMESTAMP    @"receipt_timestamp"
#define LCIM_FIELD_PAYLOAD              @"payload"
#define LCIM_FIELD_BREAKPOINT           @"breakpoint"
#define LCIM_FIELD_STATUS               @"status"

#define LCIM_INDEX_MESSAGE              @"unique_index"

#define LCIM_SQL_CREATE_MESSAGE_TABLE                        \
    @"CREATE TABLE IF NOT EXISTS " LCIM_TABLE_MESSAGE @" ("  \
        LCIM_FIELD_MESSAGE_ID           @" TEXT, "           \
        LCIM_FIELD_CONVERSATION_ID      @" TEXT, "           \
        LCIM_FIELD_FROM_PEER_ID         @" TEXT, "           \
        LCIM_FIELD_TIMESTAMP            @" NUMBERIC, "       \
        LCIM_FIELD_RECEIPT_TIMESTAMP    @" NUMBERIC, "       \
        LCIM_FIELD_PAYLOAD              @" BLOB, "           \
        LCIM_FIELD_STATUS               @" INTEGER, "        \
        LCIM_FIELD_BREAKPOINT           @" BOOL, "           \
        @"PRIMARY KEY(" LCIM_FIELD_MESSAGE_ID @")"           \
    @")"

#define LCIM_SQL_CREATE_MESSAGE_UNIQUE_INDEX                   \
@"CREATE UNIQUE INDEX IF NOT EXISTS " LCIM_INDEX_MESSAGE @" "  \
    @"ON " LCIM_TABLE_MESSAGE @"("                             \
        LCIM_FIELD_CONVERSATION_ID  @", "                      \
        LCIM_FIELD_MESSAGE_ID       @", "                      \
        LCIM_FIELD_TIMESTAMP                                   \
    @")"

#define LCIM_SQL_INSERT_MESSAGE                           \
    @"INSERT OR REPLACE INTO " LCIM_TABLE_MESSAGE  @" ("  \
        LCIM_FIELD_MESSAGE_ID           @", "             \
        LCIM_FIELD_CONVERSATION_ID      @", "             \
        LCIM_FIELD_FROM_PEER_ID         @", "             \
        LCIM_FIELD_TIMESTAMP            @", "             \
        LCIM_FIELD_RECEIPT_TIMESTAMP    @", "             \
        LCIM_FIELD_PAYLOAD              @", "             \
        LCIM_FIELD_STATUS               @", "             \
        LCIM_FIELD_BREAKPOINT                             \
    @") VALUES(?, ?, ?, ?, ?, ?, ?, ?)"

#define LCIM_SQL_UPDATE_MESSAGE                     \
    @"UPDATE " LCIM_TABLE_MESSAGE        @" "       \
    @"SET "                                         \
        LCIM_FIELD_FROM_PEER_ID          @" = ?, "  \
        LCIM_FIELD_TIMESTAMP             @" = ?, "  \
        LCIM_FIELD_RECEIPT_TIMESTAMP     @" = ?, "  \
        LCIM_FIELD_PAYLOAD               @" = ?, "  \
        LCIM_FIELD_STATUS                @" = ? "   \
    @"WHERE " LCIM_FIELD_CONVERSATION_ID @" = ? "   \
    @"AND " LCIM_FIELD_MESSAGE_ID @" = ?"

#define LCIM_SQL_MESSAGE_WHERE_CLAUSE              \
    @"WHERE " LCIM_FIELD_CONVERSATION_ID @" = ? "  \
    @"AND " LCIM_FIELD_MESSAGE_ID @" = ?"

#define LCIM_SQL_SELECT_MESSAGE_BY_ID              \
    @"SELECT * FROM " LCIM_TABLE_MESSAGE @" "      \
    LCIM_SQL_MESSAGE_WHERE_CLAUSE

#define LCIM_SQL_SELECT_TIMESTAMP  \
    @"SELECT " LCIM_FIELD_TIMESTAMP @" FROM " LCIM_TABLE_MESSAGE @" "  \
    LCIM_SQL_MESSAGE_WHERE_CLAUSE

#define LCIM_SQL_SELECT_MESSAGE_LESS_THAN_TIMESTAMP  \
    @"SELECT * FROM " LCIM_TABLE_MESSAGE @" "        \
    @"WHERE " LCIM_FIELD_CONVERSATION_ID @" = ? "    \
    @"AND " LCIM_FIELD_TIMESTAMP @" < ? "            \
    @"ORDER BY " LCIM_FIELD_TIMESTAMP @" DESC "      \
    @"LIMIT ?"

#define LCIM_SQL_SELECT_MESSAGE_LESS_THAN_TIMESTAMP_AND_ID  \
    @"SELECT * FROM " LCIM_TABLE_MESSAGE @" "               \
    @"WHERE " LCIM_FIELD_CONVERSATION_ID @" = ? "           \
    @"AND (" LCIM_FIELD_TIMESTAMP @" < ? OR (" LCIM_FIELD_TIMESTAMP @" = ? AND " LCIM_FIELD_MESSAGE_ID @" < ?)) "  \
    @"ORDER BY " LCIM_FIELD_TIMESTAMP @" DESC, " LCIM_FIELD_MESSAGE_ID @" DESC "  \
    @"LIMIT ?"

#define LCIM_SQL_SELECT_NEXT_MESSAGE               \
    @"SELECT * FROM " LCIM_TABLE_MESSAGE @" "      \
    @"WHERE " LCIM_FIELD_CONVERSATION_ID @" = ? "  \
    @"AND (" LCIM_FIELD_TIMESTAMP @" > ? OR (" LCIM_FIELD_TIMESTAMP @" = ? AND " LCIM_FIELD_MESSAGE_ID @" > ?)) "  \
    @"ORDER BY " LCIM_FIELD_TIMESTAMP @", " LCIM_FIELD_MESSAGE_ID @" "  \
    @"LIMIT 1"

#define LCIM_SQL_UPDATE_MESSAGE_BREAKPOINT        \
    @"UPDATE " LCIM_TABLE_MESSAGE @" "            \
    @"SET " LCIM_FIELD_BREAKPOINT @" = ? "        \
    LCIM_SQL_MESSAGE_WHERE_CLAUSE

#define LCIM_SQL_DELETE_MESSAGE             \
    @"DELETE FROM " LCIM_TABLE_MESSAGE @" " \
    LCIM_SQL_MESSAGE_WHERE_CLAUSE

#define LCIM_SQL_DELETE_ALL_MESSAGES_OF_CONVERSATION  \
    @"DELETE FROM " LCIM_TABLE_MESSAGE @" "           \
    @"WHERE " LCIM_FIELD_CONVERSATION_ID @" = ?"      \

#define LCIM_SQL_LATEST_MESSAGE  \
    @"SELECT * FROM " LCIM_TABLE_MESSAGE @" "      \
    @"WHERE " LCIM_FIELD_CONVERSATION_ID @" = ? "  \
    @"ORDER BY " LCIM_FIELD_TIMESTAMP @" DESC "    \
    @"LIMIT ?"

#define LCIM_SQL_LATEST_NO_BREAKPOINT_MESSAGE      \
    @"SELECT *, MAX(" LCIM_FIELD_TIMESTAMP @") "   \
    @"FROM " LCIM_TABLE_MESSAGE @" "               \
    @"WHERE " LCIM_FIELD_CONVERSATION_ID @" = ? "  \
    @"AND " LCIM_FIELD_BREAKPOINT @" = 0"

#define LCIM_SQL_CLEAN_MESSAGE                    \
    @"DELETE FROM " LCIM_TABLE_MESSAGE   @" "     \
    @"WHERE " LCIM_FIELD_CONVERSATION_ID @" = ?"

#endif
