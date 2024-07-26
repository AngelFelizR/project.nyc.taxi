
check_db_columns = function(conn,
                            table_name,
                            col_names) {

  db_table_cols =
    DBI::dbGetQuery(conn = conn,
                    glue::glue_safe("SELECT * FROM {table_name} WHERE FALSE")) |>
    names()

  missing_cols = setdiff(col_names, db_table_cols)

  if(length(missing_cols) > 0L){
    missing_cols_collapse = paste0(missing_cols, collapse = ", ")
    stop(glue::glue_safe("{table_name} is missing: {missing_cols_collapse}"))
  }

}
