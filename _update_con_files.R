update_con_files <- function(){
  paths <- c("docs/index.html", "docs/index.xml", "docs/posts/posts.json", "docs/sitemap.xml")
  purrr::walk(paths, function(x){
    new <- readr::read_file_raw(glue::glue("https://raw.githubusercontent.com/nflverse/open-source-football/master/{x}"))
    readr::write_file(new, x)
  })
}
update_con_files()
