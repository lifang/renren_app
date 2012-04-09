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
        if(web=="renren"||web=="sina"||web=="baidu"||web=="qq"){
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
        tishi_alert("页面即将刷新,请稍等 :)");
    }
}

function confirm_share(){
    $('#free_sum_div').hide();
    var message = "";
    if(web=="renren"){
        message = "发送一条新鲜事到您的主页来宣传我们的应用";
    }
    if(web=="sina"){
        message = "发送一条微博到您的主页来宣传我们的应用";
    }
    if(web=="baidu"){
        share();
        return false;
    }
    $("#confirm_share_message").html("领取免费名额，我们将"+message+"，感谢您的支持。确认领取吗？");
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
    if(web=="baidu"){
        $.ajax({
            type: "GET",
            url: "/similarities/baidu_share"+type_n+".json",
            dataType: "json",
            success: function(data){
                tishi_alert(data.message);
                if(data["error"]==null){
                    shared = 1;
                    window.location.href="/similarities/refresh?category="+category_id+"&web=baidu&success=success";
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

//qq空间发表说说
function qq_share(){
    $("#free_sum_div").css("display","none");
    var img_url=$("#img_url").val();
    fusion2.dialog.share
    ({
        // 可选。分享应用的URL，点击该URL可以进入应用，必须是应用在平台内的地址。
        url:"http://rc.qzone.qq.com/myhome/100625119",
        // 可选。默认展示在输入框里的分享理由。

        desc:"由赶考网提供，1996年至2011年全部新大学英语四级真题，提供在线练习功能。参与分享可以获得所有真题的免费体验资格,赶快来试试吧",
        // 必须。应用简要描述。

        summary :"由赶考网提供，1996年至2011年全部新大学英语四级真题，提供在线练习功能。",
        // 必须。分享的标题。

        title :"英语四级真题",
        // 可选。图片的URL。

        pics :img_url,
        // 可选。透传参数，用于onSuccess回调时传入的参数，用于识别请求。
        context:"share",
        // 可选。用户操作后的回调方法。
        onSuccess : function (opt) {
            $.ajax({
                type: "POST",
                url: "/similarities/qq_confirm.json",
                dataType: "json",
                success: function(data){
                    tishi_alert(data.notice);
                    if(data.fresh){
                        window.location.href="/similarities?category="+data.category+"&web=qq";
                    }
                }
            })
        },

        // 可选。用户取消操作后的回调方法。
        onCancel : function () {
            tishi_alert("取消分享将不会获得正式会员资格,你只能免费使用三场真题考试");
        },

        // 可选。对话框关闭时的回调方法。
        onClose : function () {
        }

    });
}


function qq_share_6(){
    $("#free_sum_div").css("display","none");
    var img_url=$("#img_url").val();
    fusion2.dialog.share
    ({
        // 可选。分享应用的URL，点击该URL可以进入应用，必须是应用在平台内的地址。
        url:"http://rc.qzone.qq.com/myhome/100625123",
        // 可选。默认展示在输入框里的分享理由。

        desc:"由赶考网提供，1996年至2011年全部新大学英语六级真题，提供在线练习功能。参与分享可以获得所有六级真题的免费体验资格,赶快来试试吧",
        // 必须。应用简要描述。

        summary :"由赶考网提供，1996年至2011年全部新大学英语六级真题，提供在线练习功能。",
        // 必须。分享的标题。

        title :"英语六级真题",
        // 可选。图片的URL。

        pics :img_url,
        // 可选。透传参数，用于onSuccess回调时传入的参数，用于识别请求。
        context:"share",
        // 可选。用户操作后的回调方法。
        onSuccess : function (opt) {
            $.ajax({
                type: "POST",
                url: "/similarities/qq_confirm_6.json",
                dataType: "json",
                success: function(data){
                    tishi_alert(data.notice);
                    if(data.fresh){
                        window.location.href="/similarities?category="+data.category+"&web=qq";
                    }
                }
            })
        },

        // 可选。用户取消操作后的回调方法。
        onCancel : function () {
            tishi_alert("取消分享将不会获得正式会员资格,你只能免费使用三场真题考试");
        },

        // 可选。对话框关闭时的回调方法。
        onClose : function () {
        }

    });
}