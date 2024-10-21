@EndUserText.label: 'CDS Consumption for DB Table'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
define view entity zc_db_data
  as projection on zi_db_data
{
  key end_user,
  key Entrysheet,
  key Ebeln,
  key Ebelp,
      Ext_Number,
      Begdate,
      Enddate,
      Quantity,
      Base_Uom,
      Fin_Entry,
      Error,
      Error_Message,
      /* Associations */
      _file : redirected to parent zc_file_table
}
