  $(function() {

  //takes the id of the chosen student and sets it in the dialog
  $(document).on("click", ".promote", function () {
     var user_id = $(this).data('id');
     $(".user-id").val( user_id ); 
   });

   $(document).on("click", ".demote", function () {
     var user_id = $(this).data('id');
     $(".user_id").val( user_id ); 

     $.ajax({
        type: "GET",
        dataType: "json",
        url: "/userlist",
        data: {
          exclude_user : user_id
        },
        success: function(data){
          if (data.is_deputy){
            $("#new_deputy_id").css("visibility", "visible");
            var options = $("#new_deputy_id");
            $("#new_deputy_id").empty();
            $.each(data.users, function(index, user){
              options.append('<option value=' + user.id+ '>' + user.full_name + '</option>');
            })
          } 
          else {
            $("#new_deputy_id").empty();
            $("#new_deputy_id").css("visibility", "hidden");
          }     
        },
        error: function(xhr, ajaxOptions, thrownError){
          console.log("HTTP-Status = "+ xhr.status);
          console.log(thrownError);
          console.log(xhr.responseText)
        }
     })
   });


  //when the role of a student is changed to Admin, the drop-down menu with the different chairs is not visible
  $("#role_level").change(function(event){

    if(event.target.options[event.target.selectedIndex].text == "Admin"){
      $("#employer_id").css('visibility', 'hidden')
    }
    else {
      $("#employer_id").css('visibility', 'visible')
    }
  });
})
