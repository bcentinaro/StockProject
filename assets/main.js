$(document).ready(function(){
  //check if SearchForm exists in DOM
  if($('#searchForm').length > 0){
    $('#searchForm').submit(function(){
      console.log('changing!');
      $('#searchForm').before('<h1>Loading Results...</h1><h3>this may take a couple of seconds.</h3>');
      $('#searchForm').hide();
      return true
    });

    $('#stock').keyup(function(){
      value = $('#stock').val()
      period = $('#period').val()
      var values =value.split(",");
      $('#searchForm').attr('action', "/stock/" + values.join("_") + '/' + period + '.html')
      jQuery.get("/stock/pre-fetch/" + values.join("_"));
    });
  }

  // check if index exists in DOM
  if($('#index').length > 0){
  }

});