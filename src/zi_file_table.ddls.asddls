@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'CDS for file'
define root view entity zi_file_table
  as select from    zauser331      as _user
    left outer join zafiletable331 as _file on _user.bname = _file.end_user
  composition [0..*] of zi_db_data as _dbdata
{
  key    _user.bname                                                                                            as end_user,                                                                                       
         _file.status                                                                                           as status,
         cast( case when _file.filename is initial and _file.status is      initial then 'File Not Uploaded'
                    when _file.filename is not initial and  _file.status is initial  then 'File Uploaded'
                    when _file.filename is initial then 'File Not Uploaded'
                    when  _file.status is not initial then 'File Processed' else ' ' end as abap.char( 20 ) )   as FileStatus,
         case when _file.filename is initial and _file.status is initial then '1'
                    when _file.filename is not initial and  _file.status is initial  then '2'
                    when _file.filename is initial then '1'
                    when  _file.status is not initial then '3'
                    else ''
         end                                                                                                    as CriticalityStatus,
         cast( case when _file.filename is not initial then ' ' else 'X' end as abap_boolean preserving type  ) as HideExcel,
         @Semantics.largeObject:
                             { mimeType: 'MimeType',
                               fileName: 'Filename',
                    acceptableMimeTypes: [ 'text/csv' ],
         contentDispositionPreference: #INLINE } // This will store the File into our table
         _file.attachment                                                                                       as Attachment,
         @Semantics.mimeType: true
         _file.mimetype                                                                                         as MimeType,
         _file.filename                                                                                         as Filename,
         @Semantics.user.createdBy: true
         _file.local_created_by                                                                                 as Local_Created_By,
         @Semantics.systemDateTime.createdAt: true
         _file.local_created_at                                                                                 as Local_Created_At,
         @Semantics.user.lastChangedBy: true
         _file.local_last_changed_by                                                                            as Local_Last_Changed_By,
         //local ETag field --> OData ETag
         @Semantics.systemDateTime.localInstanceLastChangedAt: true
         _file.local_last_changed_at                                                                            as Local_Last_Changed_At,
         //total ETag field
         @Semantics.systemDateTime.lastChangedAt: true
         _file.last_changed_at                                                                                  as Last_Changed_At,
         _dbdata

}
where
  _user.bname = $session.user
