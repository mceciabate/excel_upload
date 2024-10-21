CLASS zcl_gendata_users DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_oo_adt_classrun .
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_gendata_users IMPLEMENTATION.


  METHOD if_oo_adt_classrun~main.


    DATA lt_user TYPE STANDARD TABLE OF zauser331.

    lt_user = VALUE #( ( client = '100'
                         bname = 'CB9980002565' ) ).

    DELETE FROM zauser331.

    INSERT  zauser331 FROM TABLE @lt_user.
    IF sy-subrc = 0.
      COMMIT WORK.
      out->write( |DONE: { sy-dbcnt }| ).
    ELSE.
      ROLLBACK WORK.
      out->write( |FAIL| ).
    ENDIF.


  ENDMETHOD.
ENDCLASS.
