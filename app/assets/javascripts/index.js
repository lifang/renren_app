function already_submit(eu_id,ex_id,sheet_url){
    $("#already_submit_div").show();
    $("#already_submit_eu_id").val(eu_id);
    $("#already_submit_ex_id").val(ex_id);
    $("#already_submit_sheet_url").val(sheet_url);
    return false;
}

function view_paper(){
    var eu_id = $("#already_submit_eu_id").val();
    $("#already_submit_div").hide();
    window.location.href="/similarities/"+eu_id+"/join?category="+category_id+"&web="+web;
}

function redo_paper(){
    var ex_id = $("#already_submit_ex_id").val();
    var sheet_url = $("#already_submit_sheet_url").val();
    sheet_url = public_path+sheet_url;
    $("#already_submit_div").hide();
    window.location.href="/similarities/"+ex_id+"/redo_paper?category="+category_id+"&sheet_url="+sheet_url+"&web="+web;
}


function tishi_share(content){
    if(shared == 0){
        $('#free_sum_div').show();
        $('#display_free_sum').html("");
        $('#tishi_share_content').html(content);
        if(web=="renren"||web=="sina"){
            $.ajax({
                type: "GET",
                url: "/similarities/ajax_free_sum.json",
                dataType: "json",
                data : {
                    "category":category_id,
                    "order_type":order_type
                },
                success: function(data){
                    $('#display_free_sum').html(data.message);
                }
            });
        }
    }else{
        tishi_alert("请等待页面刷新");
    }
}

function confirm_share(){
    $('#free_sum_div').hide();
    if(web=="renren"){
        $("#confirm_share_message").html("领取免费名额，我们将发送一条新鲜事到您的主页来宣传我们的应用，感谢您的支持。确认领取吗？");
    }
    if(web=="sina"){
        $("#confirm_share_message").html("领取免费名额，我们将发送一条微博到您的主页来宣传我们的应用，感谢您的支持。确认领取吗？");
    }
    $('#confirm_share_div').show();
}

function share(){
    $('#confirm_share_div').hide();
    tishi_alert("正在处理，请稍候...");
    if(web=="renren"){
        $.ajax({
            type: "GET",
            url: "/similarities/renren_share"+type_n+".json",
            dataType: "json",
            success: function(data){
                tishi_alert(data.message);
                if(data["error"]==null){
                    shared = 1;
                    window.location.href="/similarities/refresh?category="+category_id+"&web=renren&success=success";
                }
            }
        });
    }
    if(web=="sina"){
        $.ajax({
            type: "POST",
            url: "/similarities/sina_share"+type_n+".json",
            dataType: "json",
            data:{
                "message":$("#sina_share_message").val()
            },
            success: function(data){
                tishi_alert(data.message);
                if(data["error"]==null){
                    shared = 1;
                    window.location.href="/similarities/refresh?category="+category_id+"&web=sina&success=success";
                }
            }
        });
    }
}

function friends(){
    $('#guanzhu_div').hide();
    window.open("http://widget.renren.com/dialog/friends?target_id="+renren_id+"&app_id="+app_id+"&redirect_uri="+server_path+"/similarities/close_window","_blank","height=400,width=980,left=200,top=150");
}

$(function(){
    if(success=="1"){
        tishi_alert("您已升级为正式用户,感谢您的支持。");
    }
})