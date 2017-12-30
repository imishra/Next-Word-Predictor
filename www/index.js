$(document).ready(function(){
	$("#predict").click(function(){
		var text=$("#text").val()
		if(text.length>0){
			$('.outputText').show();
			$('#table').show(200);
			return true;
		}
		else{
			$('#table').hide(200);
			$('.outputText').hide();
			return false;
		}
	});
	$("#text").on( "keydown",function(event){
		var text=$("#text").val()
		if(text.length>0){
			if(event.which==13){
				$('#predict').click();
			}
			if(event.which==32){
			        $('#predict').click();
			}
			 
		}
		else{
			$('#table').hide(200);
		}
	});
	
});
