@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'CDS for data'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define view entity zi_db_data
  as select from zadb331 as data
   association to parent zi_file_table as _file on $projection.end_user = _file.end_user
{
  key end_user           as end_user,
  key data.entrysheet    as Entrysheet,
  key data.ebeln         as Ebeln,
  key data.ebelp         as Ebelp,
      data.ext_number    as Ext_Number,
      data.begdate       as Begdate,
      data.enddate       as Enddate,
      @Semantics.quantity.unitOfMeasure: 'Base_Uom'
      data.quantity      as Quantity,
      data.base_uom      as Base_Uom,
      data.fin_entry     as Fin_Entry,
      data.error         as Error,
      data.error_message as Error_Message,
      _file
}
