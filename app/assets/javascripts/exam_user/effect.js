//此JS记录了考试页面相关的方法


//字体放大、缩小
var tgs = new Array( 'div','td','tr');
var szs = new Array( 'xx-small','x-small','small','medium','large','x-large','xx-large' );
var startSz = 2;
function ts( trgt,inc ) {
    if (!document.getElementById) return
    var d = document,cEl = null,sz = startSz,i,j,cTags;
    sz += inc;
    if ( sz < 0 ) sz = 0;
    if ( sz > 6 ) sz = 6;
    startSz = sz;
    if ( !( cEl = d.getElementById( trgt ) ) ) cEl = d.getElementsByTagName( trgt )[ 0 ];
    cEl.style.fontSize = szs[ sz ];
    for ( i = 0 ; i < tgs.length ; i++ ) {
        cTags = cEl.getElementsByTagName( tgs[ i ] );
        for ( j = 0 ; j < cTags.length ; j++ ) cTags[ j ].style.fontSize = szs[ sz ];
    }
}

//下一题
function click_next_problem(){
    var this_problem = $(".problem_resource:visible");
    var next_problem = this_problem.next(".problem_resource");
    if(init_problem>=(problems.length-1)){
        tishi_alert("当前已是最后一题");
        return false;
    }else{
        init_problem += 1;
        active(this_problem,next_problem);
    }
}

//上一题
function click_prev_problem(){
    var this_problem = $(".problem_resource:visible");
    var prev_problem = this_problem.prev(".problem_resource");
    if(init_problem<=0){
        tishi_alert("当前已是第一题");
        return false;
    }else{
        init_problem -= 1;
        active(this_problem,prev_problem);
    }
}

function active(this_problem,old_problem){
    $("#report_error").hide();
    $("#global_problem_index").html(init_problem+1);
    if(old_problem.length>0){
        old_problem.show();
        if(mp3s[init_problem]){
            $("#flowplayer_location_"+init_problem).attr("style","display:block;width:350px;height:30px;margin:auto;margin-top:10px;");
            $("#flowplayer_location_"+init_problem).attr("href","http://test.mp3");
            clone_flowplayer(("#flowplayer_location_"+init_problem),mp3s[init_problem]);
        }
        // 展开题目的第一题
        if(problems[init_problem].question_type!="1"){
            $("#pro_qu_t_"+init_problem+"_0").trigger("click");
        }
    }else{
        load_problem(init_problem);
    }
    this_problem.hide();
}


last_opened_question = null;
last_backg_blue = null;
//初始化显示、隐藏小题功能
function pro_qu_t(problem_index){
    $(".pro_qu_t_"+problem_index).bind("click",function(){
        if(!$(this).is(":visible")){
            return false;
        }
        var pro_qu_div = $(this).parent().find(".pro_qu_div");
        var replace_answer_span = $(this).children(".replace_description_span");
        var q_index =$(this).attr("name");
        if(pro_qu_div.is(":visible")){
            pro_qu_div.hide();
            replace_answer_span.show();
            $(this).parent().parent().addClass("p_q_line");
            if(problems[problem_index]["question_type"]=="1"){
                $(".inner_backg_blue_"+problem_index+"_"+q_index+":eq(0)").removeClass("backg_blue");
                last_backg_blue = null;
            }
            last_opened_question = null;
        }else{
            pro_qu_div.show();
            replace_answer_span.hide();
            $(this).parent().parent().removeClass("p_q_line");
            if(problems[problem_index]["question_type"]=="1"){
                $(".inner_backg_blue_"+problem_index+"_"+q_index+":eq(0)").addClass("backg_blue");
            }
            if(last_opened_question!=null){
                last_opened_question.parent().find(".pro_qu_div").hide();
                last_opened_question.children(".replace_description_span").show();
                last_opened_question.parent().parent().addClass("p_q_line");
                if(last_backg_blue!=null && last_backg_blue.length>0 ){
                    last_backg_blue.removeClass("backg_blue");
                }
            }
            last_backg_blue = $(".inner_backg_blue_"+problem_index+"_"+q_index+":eq(0)");
            last_opened_question = $(this);
        }
    })
}

//题面后小题列表改变颜色
function change_color(value,problem_index,question_index){
    if(value=="1"){
        $("#color_flag_"+problem_index+"_"+question_index).attr("class","ture_green");
    }else{
        if(value=="0"){
            $("#color_flag_"+problem_index+"_"+question_index).attr("class","false_red");
        }
        else{
            $("#color_flag_"+problem_index+"_"+question_index).attr("class","un_white");
        }
    }
}

//单选题,做题
function do_single_choose(ele,problem_index,question_index){
    attrs=problems[problem_index].questions.question[question_index].questionattrs.split(";-;");
    $(".single_choose_li_"+problem_index+"_"+question_index).removeClass("hover");
    $(ele).addClass("hover");
    var n=0;
    $(".single_choose_li_"+problem_index+"_"+question_index).each(function(){
        if($(this).hasClass("hover")){
            $("#exam_user_answer_"+problem_index+"_"+question_index).val(attrs[n]);
            return false;
        }
        n++;
    });
}

//多选题，做题
function do_multi_choose(ele,problem_index,question_index){
    attrs=problems[problem_index].questions.question[question_index].questionattrs.split(";-;");
    $(ele).toggleClass("hover");
    var n = 0;
    var user_answer = [];
    $(".multi_choose_li_"+problem_index+"_"+question_index).each(function(){
        if($(this).hasClass("hover")){
            user_answer.push(attrs[n]);
        }
        n++;
    });
    $("#exam_user_answer_"+problem_index+"_"+question_index).val(user_answer.join(";|;"));
}

//判断，做题
function do_judge(ele,answer,problem_index,question_index){
    $(".judge_li_"+problem_index+"_"+question_index).removeClass("hover");
    $(ele).addClass("hover");
    $("#exam_user_answer_"+problem_index+"_"+question_index).val(answer);
}

function do_fill_blank(ele,answer,problem_index,question_index){
    $("#exam_user_answer_"+problem_index+"_"+question_index).val(answer);
}

//小题做对或者做错的效果显示
function right_or_error_effect(user_answer,answer,analysis,problem_index,question_index,question_type,correct_type){
    if(user_answer==answer){
        $("#pass_check_"+problem_index+"_"+question_index).val(1);
        $("#green_dui_"+problem_index+"_"+question_index).show();
        $("#red_cuo_"+problem_index+"_"+question_index).hide();
        change_color("1",problem_index,question_index);
        if(question_type=="1"){
            if(correct_type=="1"){
                $("#droppable_"+problem_index+"_"+question_index).addClass("span_right");
            }else{
                $("#input_inner_answer_"+problem_index+"_"+question_index).addClass("span_right");
            }
        }
    }else{
        $("#pass_check_"+problem_index+"_"+question_index).val(0);
        $("#green_dui_"+problem_index+"_"+question_index).hide();
        $("#red_cuo_"+problem_index+"_"+question_index).show();
        change_color("0",problem_index,question_index);
        if(question_type=="1"){
            if(correct_type=="1"){
                $("#droppable_"+problem_index+"_"+question_index).addClass("span_error");
            }else{
                $("#input_inner_answer_"+problem_index+"_"+question_index).addClass("span_error");
            }
        }
    }
    $("#display_jiexi_"+problem_index+"_"+question_index).show();
    $("#display_analysis_"+problem_index+"_"+question_index).html(analysis);
    $("#check_question_btn_"+problem_index+"_"+question_index).hide();
    $("#next_question_btn_"+problem_index+"_"+question_index).show();
    $("#open_display_answer_"+problem_index+"_"+question_index).show();

    //题面内核对按钮消失，让用户无法再次更改答案
    if(question_type=="0"){
        if(correct_type=="0"){
            $(".single_choose_li_"+problem_index+"_"+question_index).attr("onclick","");
        }
        if(correct_type=="1"){
            $(".multi_choose_li_"+problem_index+"_"+question_index).attr("onclick","");
        }
        if(correct_type=="2"){
            $(".judge_li_"+problem_index+"_"+question_index).attr("onclick","");
        }
        if(correct_type=="3" || correct_type=="5"){
            $("#fill_input_"+problem_index+"_"+question_index).attr("readonly","readonly");
        }
    }
    if(question_type=="1"){
        $("#hedui_btn_"+problem_index+"_"+question_index).parent().hide();
        $("#inner_span_tk_"+problem_index+"_"+question_index).attr("onmouseover","");
        $("#inner_span_tk_"+problem_index+"_"+question_index).attr("onmouseout","");
        if(correct_type=="0"){
            $(".select_li_"+problem_index+"_"+question_index).attr("onclick","javascript:$(\"#select_ul_"+problem_index+"_"+question_index+"\").hide();");
            $("#select_ul_"+problem_index+"_"+question_index).attr("onclick","javascript:$(\"#select_ul_"+problem_index+"_"+question_index+"\").hide();");
        }
        if(correct_type=="1"){
            $("#droppable_"+problem_index+"_"+question_index).droppable({
                drop: function( event, ui ) {
                    tishi_alert("此小题已经核对");
                }
            })
        }
        if(correct_type=="3"){
            $("#input_inner_answer_"+problem_index+"_"+question_index).attr("readonly","readonly");
        }
        $("#inner_span_tk_"+problem_index+"_"+question_index).bind("click",function(){
            if(!$("#pro_qu_t_"+problem_index+"_"+question_index).parent().find(".pro_qu_div").is(":visible")){
                $("#pro_qu_t_"+problem_index+"_"+question_index).trigger("click");
            }
        })
    }
    if(problems[problem_index].questions.question[question_index]["description"]==null || problems[init_problem].questions.question[question_index]["description"]==""){
        user_answer = (user_answer == "1" ? "对/是" : (user_answer == "0" ? "错/否" : user_answer.replace(/;\|;/g," , ")));
        $("#replace_description_span_"+init_problem+"_"+question_index).html(user_answer);
    }
    //改变最终显示答案的内容，如单选题可以只显示"A"
    answer = change_display_answer(correct_type,answer);
    $("#display_answer_"+problem_index+"_"+question_index).html(answer);
}

//根据题目类型，设置最终显示的答案效果
function change_display_answer(correct_type,answer){
    if(correct_type=="0"){
        answer=answer.split(")")[0];
    }
    if(correct_type=="1"){
        var split_answer = answer.split(";|;");
        var answer_arr=[];
        for(var i=0;i<split_answer.length;i++){
            answer_arr.push(split_answer[i].split(")")[0]);
        }
        answer=answer_arr.join(",");
    }
    if(correct_type=="2"){
        if(answer=="1"){
            answer="对/是";
        }else{
            answer="错/否";
        }
    }
    return answer
}

//核对小题
function check_question(question_type,correct_type,problem_index,question_index){
    var attrs = problems[problem_index].questions.question[question_index]["questionattrs"];
    if(question_type!="0" && question_type!="1"){
        question_type="0";
    }
    if($("#exam_user_answer_"+problem_index+"_"+question_index).val()==""){
        tishi_alert("请做题后再核对");
        return false;
    }
    $("#display_answer_"+problem_index+"_"+question_index).empty();
    $("#display_analysis_"+problem_index+"_"+question_index).empty();
    var answer = $.trim(answers[problem_index][question_index].answer);
    var analysis = answers[problem_index][question_index].analysis;
    var user_answer = $.trim($("#exam_user_answer_"+problem_index+"_"+question_index).val());
    if(sheet_url!=""){
        //保存用户答案
        $.ajax({
            type: "POST",
            url: "/similarities/"+init_exam_user_id+"/ajax_save_question_answer.json",
            dataType: "json",
            data : {
                "category_id":category,
                "sheet_url":sheet_url,
                "question_type":question_type,
                "correct_type":correct_type,
                "problem_index":problem_index,
                "question_index":question_index,
                "answer":user_answer
            }
        });
    }
    //改变答题正误的显示效果细节
    right_or_error_effect(user_answer,answer,analysis,problem_index,question_index,question_type,correct_type);

    if($("#exam_user_answer_"+problem_index+"_"+question_index).val()!="" && question_type=="1"){
        $("#tk_zuoda_"+problem_index).hide();
        $(".pro_question_list_"+problem_index+":eq("+question_index+")").show();
        $("#pro_qu_t_"+problem_index+"_"+question_index).trigger("click");
    }

    //判断是否最后一小题，若是，则改变答卷状态 status="1"
    if((question_index+1)>=answers[problem_index].length && (problem_index+1)>=problems.length){
        if(sheet_url!=""){
            $.ajax({
                type: "POST",
                url: "/similarities/"+init_exam_user_id+"/ajax_change_status.json",
                dataType: "json",
                data : {
                    "sheet_url":sheet_url
                }
            });
        }
    }
}

//根据保存的用户答案，改变小题状态
function refer_question(question_type,correct_type,problem_index,question_index){
    if(question_type!="0" && question_type!="1"){
        question_type="0";
    }
    var answer = $.trim(answers[problem_index][question_index].answer);
    var analysis = answers[problem_index][question_index].analysis;
    var user_answer = $.trim(sheet["_"+problem_index+"_"+question_index]);
    //直接改变小题的背景颜色
    if(user_answer==answer){
        change_color("1",problem_index,question_index);
    }else{
        change_color("0",problem_index,question_index);
    }
    if(question_type=="1"){
        $("#tk_zuoda_"+problem_index).hide();
        $(".pro_question_list_"+problem_index+":eq("+question_index+")").show();
    }
    //改变答题正误的显示效果细节
    right_or_error_effect(user_answer,answer,analysis,problem_index,question_index,question_type,correct_type);
    //模拟用户操作，如单选题选择了哪个，selector选中哪个
    imitate_action(question_type,correct_type,user_answer,problem_index,question_index);
}

//模拟用户操作
function imitate_action(question_type,correct_type,user_answer,problem_index,question_index){
    $("#exam_user_answer_"+problem_index+"_"+question_index).val(user_answer);
    if(question_type=="0"){
        if(correct_type=="0"){
            var attrs = problems[problem_index].questions.question[question_index]["questionattrs"];
            var split_attrs = attrs.split(";-;");
            for(var i=0;i<split_attrs.length;i++){
                if($.trim(user_answer)==$.trim(split_attrs[i])){
                    $(".single_choose_li_"+problem_index+"_"+question_index+":eq("+i+")").addClass("hover");
                }
            }
        }
        if(correct_type=="1"){
            var attrs = problems[problem_index].questions.question[question_index]["questionattrs"];
            var split_attrs = attrs.split(";-;");
            var user_answer_arr = user_answer.split(";|;");
            for(var ii=0;ii<user_answer_arr.length;ii++){
                for(var j=0;j<split_attrs.length;j++){
                    if($.trim(user_answer_arr[ii])==$.trim(split_attrs[j])){
                        $(".multi_choose_li_"+problem_index+"_"+question_index+":eq("+j+")").addClass("hover");
                    }
                }
            }
        }
        if(correct_type=="2"){
            if(user_answer=="1"){
                $(".judge_li_"+problem_index+"_"+question_index+":eq(0)").addClass("hover");
            }else{
                if(user_answer=="0"){
                    $(".judge_li_"+problem_index+"_"+question_index+":eq(1)").addClass("hover");
                }
            }
        }
        if(correct_type=="3"||correct_type=="5"){
            $("#fill_input_"+problem_index+"_"+question_index).val(user_answer);
        }
    }else{
        if(question_type=="1"){
            if(correct_type=="0"){
                $("#input_inner_answer_"+problem_index+"_"+question_index).html(user_answer);
            }
            if(correct_type=="1"){
                $("#droppable_"+problem_index+"_"+question_index).html(user_answer);
            }
            if(correct_type=="3"){
                $("#input_inner_answer_"+problem_index+"_"+question_index).val(user_answer);
                call_me(problem_index,question_index);
            }
        }
    }
}

//关闭答案，解析
function close_display_answer(problem_index,question_index){
    $("#display_jiexi_"+problem_index+"_"+question_index).hide();
}

//显示答案、解析
function open_display_answer(problem_index,question_index){
    $("#display_jiexi_"+problem_index+"_"+question_index).show();
}

function do_inner_select(answer,problem_index,question_index){
    $("#input_inner_answer_"+problem_index+"_"+question_index).html(answer);
    $("#exam_user_answer_"+problem_index+"_"+question_index).val(answer);
    $("#select_ul_"+problem_index+"_"+question_index).hide();
}

//用户操作题目内小题
function do_inner_question(correct_type,problem_index,question_index){
    var this_answer = $("#input_inner_answer_"+problem_index+"_"+question_index).val();
    $("#exam_user_answer_"+problem_index+"_"+question_index).val(this_answer);
}

//题面内单选题选项显示和隐藏
function toggle_select_ul(problem_index,question_index){
    if($("#select_ul_"+problem_index+"_"+question_index).is(":visible")){
        $("#select_ul_"+problem_index+"_"+question_index).hide();
    }else{
        $(".select_ul_"+problem_index).hide();
        $("#select_ul_"+problem_index+"_"+question_index).show();
    }
}

function show_hedui(problem_index,question_index){
    $("#hedui_btn_"+problem_index+"_"+question_index).parent().show();
}

function hide_hedui(problem_index,question_index){
    $("#hedui_btn_"+problem_index+"_"+question_index).parent().hide();
}

//播放音频
function jplayer_play(src){
    $("#jquery_jplayer").jPlayer("setMedia", {
        mp3: src
    });
    $("#jquery_jplayer").jPlayer("play");
}

//ajax载入相关词汇
function ajax_load_about_words(words,problem_index,question_index){
    var about_words_div = $("#about_words_position_"+problem_index+"_"+question_index).find("#about_words");
    if(about_words_div.length>0){
        about_words_div.show();
    }else{
        if($("#about_words_resource_"+problem_index+"_"+question_index).val()!=""){
            if($("#about_words_resource_"+problem_index+"_"+question_index).val()!="error"){
                $("#about_words_list").empty();
                $("#about_words_list").html($("#about_words_resource_"+problem_index+"_"+question_index).val());
                $(".single_word_li:eq(0)").trigger("click");
                $("#about_words_position_"+problem_index+"_"+question_index).append($("#about_words"));
            }else{
                tishi_alert("抱歉，未查询到相关词汇信息");
            }
        }else{
            $.ajax({
                type: "POST",
                url: "/similarities/ajax_load_about_words.json",
                dataType: "json",
                data : {
                    "words":words
                },
                success : function(data) {
                    $("#about_words_list").empty();
                    var html_str="";
                    var words_str = "";
                    for(var i=0;i<data["words"].length;i++){
                        if(data["words"][i]!=null){
                            html_str +="<li>";
                            html_str +="<a class='single_word_li' href='javascript:void(0);' onclick='javascript:show_single_word(this,"+i+");'>"+data["words"][i][0].name+"</a>";
                            html_str +="<input type='hidden' id='about_word_id_"+i+"' value='"+data["words"][i][0].id+"' />";
                            html_str +="<input type='hidden' id='about_word_name_"+i+"' value='"+data["words"][i][0].name+"' />";
                            html_str +="<input type='hidden' id='about_word_category_id_"+i+"' value='"+data["words"][i][0].category_id+"' />";
                            html_str +="<input type='hidden' id='about_word_en_mean_"+i+"' value='"+data["words"][i][0].en_mean+"' />";
                            html_str +="<input type='hidden' id='about_word_ch_mean_"+i+"' value='"+data["words"][i][0].ch_mean+"' />";
                            html_str +="<input type='hidden' id='about_word_types_"+i+"' value='"+data["words"][i][0].types+"' />";
                            html_str +="<input type='hidden' id='about_word_phonetic_"+i+"' value=\""+data["words"][i][0].phonetic+"\" />";
                            html_str +="<input type='hidden' id='about_word_enunciate_url_"+i+"' value='"+data["words"][i][0].enunciate_url+"' />";
                            html_str +="<input type='hidden' id='about_word_sentences_"+i+"' value='"+data["words"][i][1]+"' />";
                            html_str +="</li>";
                        }
                    }
                    if(data["words"].length>0){
                        $("#about_words_resource_"+problem_index+"_"+question_index).val(html_str);
                        $("#about_words_list").html(html_str);
                        $(".single_word_li:eq(0)").trigger("click");
                        $("#about_words_position_"+problem_index+"_"+question_index).append($("#about_words"));
                    }else{
                        $("#about_words_resource_"+problem_index+"_"+question_index).val("error");
                        tishi_alert("抱歉，未查询到相关词汇信息");
                    }
                }
            });
        }
    }
}

//关闭相关词汇框
function close_about_words(){
    $("#about_words_loader").append($("#about_words"));
}

//打开报告错误框
function open_report_error(question_id){
    generate_flash_div($("#report_error"));
    $("#report_error_description").val("");
    $(".report_error_radio").attr("checked",false);
    $("#report_error_question_id").val(question_id);
}

//ajax报告错误
function ajax_report_error(){
    if(!$(".report_error_radio:checked").val()){
        tishi_alert("请选择错误类型");
        return false;
    }
    if(sheet_url!=""){
        $.ajax({
            type: "POST",
            url: "/similarities/ajax_report_error.json",
            dataType: "json",
            data : {
                "post":{
                    "paper_id":$("#report_error_paper_id").val(),
                    "paper_title":$("#report_error_paper_title").val(),
                    "user_id":$("#report_error_user_id").val(),
                    "user_name":$("#report_error_user_name").val(),
                    "description":$("#report_error_description").val(),
                    "error_type":$(".report_error_radio:checked").val(),
                    "question_id":$("#report_error_question_id").val()
                }
            },
            success : function(data) {
                tishi_alert(data["message"]);
                close_report_error();
            }
        });
    }
}

//关闭报告错误框
function close_report_error(){
    $("#report_error").hide();
}

function show_single_word(ele,i){
    $(".single_word_li").removeClass("hover");
    $(ele).addClass("hover");
    $("#about_word_name").html($("#about_word_name_"+i).val());
    $("#about_word_en_mean").html($("#about_word_en_mean_"+i).val());
    $("#about_word_ch_mean").html($("#about_word_ch_mean_"+i).val());
    $("#about_word_types").html($("#about_word_types_"+i).val());
    $("#about_word_phonetic").html($("#about_word_phonetic_"+i).val());
    $("#about_word_enunciate_url").val($("#about_word_enunciate_url_"+i).val());
    $("#about_word_id").val($("#about_word_id_"+i).val());
    var sentences = $("#about_word_sentences_"+i).val().split(";");
    var sentences_html = "";
    for(var i=0;i<sentences.length;i++){
        if(sentences[i]!=""){
            sentences_html += "<li>"+sentences[i]+"</li>";
        }
    }
    $("#about_word_sentences").html(sentences_html);
}

//设置select的默认值
//function setSel(str,select,types){
//    var setinfo=false;
//    for(var i=0;i<select.options.length;i++){
//        if (types==0 && select.options[i].text==str){
//            setinfo=true;
//        }else if (types==1 && select.options[i].value==str){
//            setinfo=true;
//        }
//        if (setinfo==true){
//            select.selectedIndex=i;
//            break;
//        }
//    }
//}

function close_select_ul(problem_index,question_index){
    $("#select_ul_"+problem_index+"_"+question_index).hide();
}

//确认是否重做试卷
function confirm_redo(type){
    if(confirm("如果您选择重做此卷，所有已保存的答案都将被清空。\n您确认要重做么？")){
        var category_id = (category!=null) ? category : "2" ;
        window.location.href="/similarities/"+init_exam_user_id+"/redo_paper?category="+category_id+"&type="+type;
    }
}

//点击"下一题"按钮
function do_next_question(problem_index,question_index){
    if((question_index+1)>=answers[problem_index].length){
        //定位到下一大题的第一小题
        click_next_problem();
    }else{
        //定位到当前大题的下一小题
        $("#pro_qu_t_"+problem_index+"_"+(question_index+1)).trigger("click");
    }
}

function clone_flowplayer(selector,audio_src){
    $(selector).hide();
    $(selector).append($("#flowplayer_loader"));
    $(selector).show();
    $f("flowplayer", "/assets/flowplayer/flowplayer-3.2.7.swf", {
        plugins: {
            controls: {
                fullscreen: false,
                height: 30,
                autoHide: false
            }
        },
        clip: {
            autoPlay: false,
            onBeforeBegin: function() {
                this.close();
            }
        },
        onLoad: function() {
            this.setVolume(90);
            this.setClip(back_server_path+audio_src);
        }
    });
}

//题面后小题加入收藏夹
function normal_add_collect(problem_index,question_index){
    if(sheet_url!=""){
        $.ajax({
            type: "POST",
            url: "/similarities/ajax_add_collect.json",
            dataType: "json",
            data : {
                "sheet_url" : sheet_url,
                "paper_id" : init_paper_id,
                "problem_index" : problem_index,
                "question_index" : question_index,
                "problem" : JSON.stringify(problems[problem_index]),
                "user_answer" : $("#exam_user_answer_"+problem_index+"_"+question_index).val(),
                "addition" :  JSON.stringify(answers[problem_index][question_index]),
                "category_id" : category
            },
            success : function(data){
                $("#shoucang_"+problems[problem_index].questions.question[question_index].id).addClass("hover");
                $("#shoucang_"+problems[problem_index].questions.question[question_index].id).attr("name","已收藏");
                $("#shoucang_"+problems[problem_index].questions.question[question_index].id).attr("onclick","");
                tishi_alert("小题收藏成功");
            }
        });
    }
}

//题面中小题加入收藏夹
function special_add_collect(problem_index,question_index){
    if(sheet_url!=""){
        $.ajax({
            type: "POST",
            url: "/similarities/add_collection.json",
            dataType: "json",
            data : {
                "sheet_url" : sheet_url,
                "problem_index" : problem_index,
                "question_index" : question_index,
                "paper_id" : init_paper_id,
                "problem_json" : JSON.stringify(problems[problem_index]),
                "user_answer" : $("#exam_user_answer_"+problem_index+"_"+question_index).val(),
                "question_answer" : answers[problem_index][question_index]["answer"]==null ? "" : answers[problem_index][question_index]["answer"],
                "question_analysis" : answers[problem_index][question_index]["analysis"]==null ? "" : answers[problem_index][question_index]["analysis"],
                "problem_id" : problems[problem_index].id,
                "question_id" : problems[problem_index].questions.question[question_index].id,
                "category_id" :category
            },
            success : function(data){
                $("#shoucang_"+problems[problem_index].questions.question[question_index].id).addClass("hover");
                $("#shoucang_"+problems[problem_index].questions.question[question_index].id).attr("name","已收藏");
                $("#shoucang_"+problems[problem_index].questions.question[question_index].id).attr("onclick","");
                tishi_alert("小题收藏成功");
            }
        });
    }
}

//播放词汇
function play_word_enunciate(url){
    //jplayer_play(url);
    play_audio(url);
}

//添加背诵单词
function ajax_add_word(word_id){
    $.ajax({
        type: "POST",
        url: "/similarities/ajax_add_word.json",
        dataType: "json",
        data : {
            "word_id" : word_id
        },
        success : function(data){
            tishi_alert(data.message);
        }
    });
}

//根据字符长度改变文本域的长和宽
function call_me(problem_index,question_index) {
    var id = ""+problem_index+"_"+question_index;
    var max_length = 48;
    if(($("#input_inner_answer_" + id).length>0) || ($("#input_inner_answer_" + id).val() != "" )) {
        if(($("#input_inner_answer_" + id).val().length >= 11) && ($("#input_inner_answer_" + id).val().length < max_length)) {
            $("#input_inner_answer_" + id).css("width", $("#input_inner_answer_" + id).val().length*10 + "px");
        } else if ($("#input_inner_answer_" + id).val().length == max_length) {
            $("#qinput_inner_answer_" + id).css("width", max_length*10 + "px");
        } else if ($("#input_inner_answer_" + id).val().length > max_length) {
            $("#input_inner_answer_" + id).css("width", max_length*10 + 130 + "px");
        }
    }
}
