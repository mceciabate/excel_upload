CLASS lhc_exceldata DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR ExcelData RESULT result.

    METHODS createSES FOR MODIFY
      IMPORTING keys FOR ACTION ExcelData~createSES RESULT result.

ENDCLASS.

CLASS lhc_exceldata IMPLEMENTATION.

  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD createSES.
  ENDMETHOD.

ENDCLASS.

CLASS lhc_zi_file_table DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR File RESULT result.


    METHODS uploadexceldata FOR MODIFY
      IMPORTING keys FOR ACTION file~uploadexceldata RESULT result.

    METHODS fields FOR DETERMINE ON MODIFY
      IMPORTING keys FOR file~fields.

    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR file RESULT result.

ENDCLASS.

CLASS lhc_zi_file_table IMPLEMENTATION.

  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD uploadExcelData.

** Check if there exist an entry with current logged in username in parent table
    SELECT SINGLE @abap_true
    FROM zafiletable331
    WHERE end_user = @sy-uname
    INTO @DATA(lv_valid).

*** Create one entry, if it does not exist -> esto causa un error
*    IF lv_valid <> abap_true.
*      INSERT zafiletable331 FROM @( VALUE #( end_user = sy-uname ) ).
*    ENDIF.

** Read the parent instance
    READ ENTITIES OF zi_file_table IN LOCAL MODE
      ENTITY file
      ALL FIELDS WITH
      CORRESPONDING #( keys )
      RESULT DATA(lt_inv)
      REPORTED DATA(lt_new_entry_reported).

    DATA(lv_attachment) = lt_inv[ 1 ]-attachment.

    DATA: rows          TYPE STANDARD TABLE OF string, "esto podria ser xstring o rawstring directamente como el attachment?
          content       TYPE string,
*          conv          TYPE REF TO cl_abap_conv_in_ce, ->esta clase ya no está disponible
*          conv          TYPE REF TO  CX_SY_CONVERSION_CODEPAGE, "posible reemplazo https://abapedia.org/steampunk-2305-api-intersect-702/cx_sy_conversion_codepage.clas.html
          conv          TYPE REF TO cl_abap_conv_codepage, "posible reemplazo https://abapedia.org/steampunk-2111-api/cl_abap_conv_codepage.clas.html
          ls_excel_data TYPE zadb331,
          lt_excel_data TYPE STANDARD TABLE OF zadb331,
          lv_quantity   TYPE c LENGTH 10,
          lv_entrysheet TYPE ebeln,
          lt_content    TYPE STANDARD TABLE OF string.

    "posible reemplazo
    "almaceno el retuning del metodo
    DATA(lv_createin) = cl_abap_conv_codepage=>create_in( )->convert( EXPORTING source = lv_attachment ).

    "OLD CODE
*    conv = cl_abap_conv_in_ce=>create( input = lv_attachment ).
*    conv->read( IMPORTING data = content ).

    SPLIT lv_createin AT cl_abap_char_utilities=>cr_lf INTO TABLE rows. "esto es un split con delimitador?
*    SPLIT rows[ 1 ] AT '\n' INTO TABLE lt_content. "corto en el salto de linea
*    DELETE rows INDEX 1. "borro el primer registro que tiene los nombres de cada columna

    LOOP AT rows INTO DATA(ls_row).
      DATA(lv_index) = sy-tabix.
      SPLIT ls_row AT ',' INTO ls_excel_data-entrysheet
                               ls_excel_data-ebeln
                               ls_excel_data-ebelp
                               ls_excel_data-ext_number
                               ls_excel_data-begdate
                               ls_excel_data-enddate
                               lv_quantity
                               "ls_attdata-BASE_UOM
                               ls_excel_data-fin_entry.

      ls_excel_data-entrysheet = lv_entrysheet = |{ ls_excel_data-entrysheet ALPHA = IN }|.
      ls_excel_data-ebeln      = |{ ls_excel_data-ebeln ALPHA = IN }|.
      ls_excel_data-ebelp      = |{ ls_excel_data-ebelp ALPHA = IN }|.
      ls_excel_data-quantity = CONV #( lv_quantity ).
      APPEND ls_excel_data TO lt_excel_data.
    ENDLOOP.


    CLEAR: ls_row, ls_excel_data.

** Delete duplicate records -> comment from blog
    DELETE ADJACENT DUPLICATES FROM lt_excel_data.
    DELETE lt_excel_data WHERE ebeln IS INITIAL.

** Prepare the datatypes to store the data from internal table lt_excel_data to child entity through EML
    DATA lt_att_create TYPE TABLE FOR CREATE zi_file_table\_dbdata.

    lt_att_create = VALUE #( (  %cid_ref  = keys[ 1 ]-%cid_ref
                                %is_draft = keys[ 1 ]-%is_draft
                                end_user  = keys[ 1 ]-end_user
                                %target   = VALUE #( FOR ls_data IN lt_excel_data ( %cid       = |{ ls_data-ebeln }{ ls_data-ebelp }|
                                                                                   %is_draft   = keys[ 1 ]-%is_draft
                                                                                   end_user    = sy-uname
                                                                                   entrysheet  = ls_data-entrysheet
                                                                                   ebeln       = ls_data-ebeln
                                                                                   ebelp       = ls_data-ebelp
                                                                                   ext_number  = ls_data-ext_number
                                                                                   begdate     = ls_data-begdate
                                                                                   enddate     = ls_data-enddate
                                                                                   quantity    = ls_data-quantity
                                                                                  " BASE_UOM    = ls_data-
                                                                                   fin_entry   = ls_data-fin_entry
                                                                                  %control = VALUE #( end_user    = if_abap_behv=>mk-on
                                                                                                      entrysheet  = if_abap_behv=>mk-on
                                                                                                      ebeln       = if_abap_behv=>mk-on
                                                                                                      ebelp       = if_abap_behv=>mk-on
                                                                                                      ext_number  = if_abap_behv=>mk-on
                                                                                                      begdate     = if_abap_behv=>mk-on
                                                                                                      enddate     = if_abap_behv=>mk-on
*                                                                                                        quantity    = if_abap_behv=>mk-on
                                                                                                     " BASE_UOM    = ls_data-
                                                                                                      fin_entry   = if_abap_behv=>mk-on  ) ) ) ) ).
    READ ENTITIES OF zi_file_table IN LOCAL MODE
    ENTITY file
    BY \_dbdata
    ALL FIELDS WITH
    CORRESPONDING #( keys )
    RESULT DATA(lt_excel).

* Delete already existing entries from child entity -> original comment -> porque borraria los registros?????
    MODIFY ENTITIES OF zi_file_table IN LOCAL MODE
    ENTITY exceldata
    DELETE FROM VALUE #( FOR ls_excel IN lt_excel (  %is_draft = ls_excel-%is_draft
                                                     %key      = ls_excel-%key ) )
    MAPPED DATA(lt_mapped_delete)
    REPORTED DATA(lt_reported_delete)
    FAILED DATA(lt_failed_delete).

** Create the records from the new attached CSV file
    MODIFY ENTITIES OF zi_file_table IN LOCAL MODE
    ENTITY file
    CREATE BY \_dbdata
    AUTO FILL CID
    WITH lt_att_create
    MAPPED DATA(lt_mapped)
    REPORTED DATA(lt_reported)
    FAILED DATA(lt_failed).


    APPEND VALUE #( %tky = lt_inv[ 1 ]-%tky ) TO mapped-file. "->guarda el archivo?
    APPEND VALUE #( %tky = lt_inv[ 1 ]-%tky
                    %msg = new_message_with_text( severity = if_abap_behv_message=>severity-success
                                                  text = 'Excel Data Uploaded' )
                   ) TO lt_new_entry_reported-file.

    MODIFY ENTITIES OF zi_file_table IN LOCAL MODE
    ENTITY file
    UPDATE FROM VALUE #( ( %is_draft = keys[ 1 ]-%is_draft
                           end_user  = keys[ 1 ]-end_user
                           status     =  'P'
                           %data-status  = 'P'
                           %control  = VALUE #( status = if_abap_behv=>mk-on ) ) )
    MAPPED DATA(lt_mapped_update)
    REPORTED DATA(lt_reported_update)
    FAILED DATA(lt_failed_update).

*estas lecturas siguientes solo son para modificar el estado?

    READ ENTITIES OF zi_file_table IN LOCAL MODE
    ENTITY file
    ALL FIELDS WITH CORRESPONDING #( keys )
    RESULT DATA(lt_file_status).

    MODIFY ENTITIES OF zi_file_table IN LOCAL MODE
    ENTITY file
    UPDATE FROM VALUE #( FOR ls_file_status IN lt_file_status ( %is_draft = ls_file_status-%is_draft
                                                                %tky      = ls_file_status-%tky
                                                                %data     = VALUE #( status = 'C'  )
                                                                %control  = VALUE #( status = if_abap_behv=>mk-on )
                                                     ) ).

    READ ENTITIES OF zi_file_table IN LOCAL MODE
       ENTITY file
       ALL FIELDS WITH
       CORRESPONDING #( keys )
       RESULT DATA(lt_file).



    result = VALUE #( FOR ls_file IN lt_file ( %tky   = ls_file-%tky

                                               %param = ls_file ) ).


  ENDMETHOD.

  METHOD fields.

    "select user
    SELECT SINGLE @abap_true
    FROM zi_file_table
    WHERE end_user = @sy-uname
    INTO @DATA(lv_valid).

    "create one record
    "este statement rompe, no se puede hacer el insert en runtime

    IF lv_valid <> abap_true.
      INSERT zafiletable331 FROM @( VALUE #( end_user = sy-uname ) ).
*      DATA: lt_new_row        TYPE TABLE FOR CREATE zi_file_table.
*      lt_new_row   = VALUE #(
*              ( %cid = 'cid'
*                %data = VALUE #( end_user = sy-uname ) ) ).
*      MODIFY ENTITIES OF zi_file_table IN LOCAL MODE
*      ENTITY File
*      CREATE FROM lt_new_row
*      MAPPED DATA(mapped_resp)
*      FAILED DATA(failed_resp)
*      REPORTED DATA(reported_resp).
    ENDIF.

    MODIFY ENTITIES OF zi_file_table IN LOCAL MODE
    ENTITY file
    UPDATE FROM VALUE #( FOR key IN keys ( end_user        = key-end_user
                                           status          = ' ' " Accepted
                                           %control-status = if_abap_behv=>mk-on ) ).

    IF keys[ 1 ]-%is_draft = '01'.

      "call action
      MODIFY ENTITIES OF zi_file_table IN LOCAL MODE
      ENTITY file
      EXECUTE uploadexceldata
      FROM CORRESPONDING #( keys ).
    ENDIF.


  ENDMETHOD.

  METHOD get_instance_features.
  ENDMETHOD.

ENDCLASS.
