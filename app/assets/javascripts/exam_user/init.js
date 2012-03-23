
//init.js   start

var attrs = []; //拖拽题选项临时保存。
//将变量转化为数组 具体 ： null => [] , 'abc'=>['abc'] , 1=>[1] , {}=>[{}]  若是数组，则返回本身
function transform_array(object){
    var result = [];
    var resource = object;
    if(resource){
        if(resource.length){
            result = resource;
        }else{
            result.push(resource);
        }
    }
    return result;
}
//组合标准答案
var answers=[];
var a = transform_array(answer.paper.problems.problem);
for(var i=0;i<a.length;i++){
    if(a[i]!=null){
        var a1 = transform_array(a[i].question);
        answers.push(a1);
    }
}
//组合试题
var problems = [];
var b = transform_array(papers.paper.blocks.block);
for(var i=0;i<b.length;i++){
    if(b[i]!=null&&b[i].problems!=null){
        var b1 = transform_array(b[i].problems.problem);
        for(var j=0;j<b1.length;j++){
            if(b1[j].questions!=null){
                b1[j].questions.question =  transform_array(b1[j].questions.question);
                problems.push(b1[j]);
            }
        }
    }
}

function rp(str){
    str = str.replace(/&amp;/g,"&");
    str = str.replace(/&lt;/g,"<");
    str = str.replace(/&gt;/g,">");
    str = str.replace(/&acute;/g,"'");
    str = str.replace(/&quot;/g, '"');
    str = str.replace(/&brvbar;/g, '|');
    return str;
}

//init.js   end



//effect.js   start

//字体放大、缩小
var tgs = new Array( 'div','td','tr');
var szs = new Array('x-small','small','medium','large');
var startSz = 1;
function ts( trgt,inc ) {
    if (!document.getElementById) return
    var d = document,cEl = null,sz = startSz,i,j,cTags;
    sz += inc;
    if ( sz < 0 ) sz = 0;
    if ( sz > 3 ) sz = 3;
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
last_borde_blue = null;
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
                $(".inner_borde_blue_"+problem_index+"_"+q_index+":eq(0)").removeClass("borde_blue");
                last_borde_blue = null;
            }
            last_opened_question = null;
        }else{
            pro_qu_div.show();
            //replace_answer_span.hide();
            $(this).parent().parent().removeClass("p_q_line");
            if(problems[problem_index]["question_type"]=="1"){
                $(".inner_borde_blue_"+problem_index+"_"+q_index+":eq(0)").addClass("borde_blue");
            }
            if(last_opened_question!=null){
                last_opened_question.parent().find(".pro_qu_div").hide();
                last_opened_question.children(".replace_description_span").show();
                last_opened_question.parent().parent().addClass("p_q_line");
                if(last_borde_blue!=null && last_borde_blue.length>0 ){
                    last_borde_blue.removeClass("borde_blue");
                }
            }
            last_borde_blue = $(".inner_borde_blue_"+problem_index+"_"+q_index+":eq(0)");
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
                            html_str +="<input type='hidden' id='about_word_types_"+i+"' value='"+word_type[data["words"][i][0].types]+"' />";
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
    var category_id = (category!=null) ? category : "2";
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
                    "question_id":$("#report_error_question_id").val(),
                    "category_id":category_id
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

function close_select_ul(theEvent,obj,problem_index,question_index){ //theEvent用来传入事件，Firefox的方式
    var browser=navigator.userAgent;   //取得浏览器属性
    if (browser.indexOf("MSIE")>0){ //如果是IE
        if (obj.contains(event.toElement)) return; // 如果是子元素则结束函数
    }else{ //如果是Firefox
        if (obj.contains(theEvent.relatedTarget)) return; // 如果是子元素则结束函数
    }
    /*要执行的操作*/
    $("#select_ul_"+problem_index+"_"+question_index).hide();
}

//确认是否重做试卷
function confirm_redo(web){
    if(confirm("如果您选择重做此卷，所有已保存的答案都将被清空。\n您确认要重做么？")){
        var category_id = (category!=null) ? category : "2" ;
        window.location.href="/similarities/"+init_exam_user_id+"/redo_paper?category="+category_id+"&web="+web;
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
                tishi_alert(data.message);
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
                tishi_alert(data.message);
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
    var max_length = $("#m_side_"+problem_index).width();
    var text_length=$("#input_inner_answer_" + id).val().length*8;
    if(($("#input_inner_answer_" + id).length>0) || ($("#input_inner_answer_" + id).val() != "" )) {
        var max=text_length>(max_length-40)?(max_length-40): text_length;
        $("#input_inner_answer_" + id).css("width", max + "px");
    }
}

//effect.js   end



//generate.js  start

var q_type = {
    "0":"单选题",
    "1":"多选题",
    "2":"判断题",
    "3":"填空题",
    "5":"简答题"
};
var finish_index;  //记录前一题的序号，区别“上一题”，“下一题”效果
var element1;
var element2;
var elememt3;
var store1;
var store2;
var store3;
var str1;
var question_attrs=[]; //存储小题选项
var attr; //单个选项
var sign; //选项标志，如 A B C
var content; //选项内容
var drag_attrs=[]; //存储拖选题选项
var has_drag; // 有拖选题？
var mp3; //记录当前音频
var i; //循环体参数
var j; //循环体参数
var q; //小题循环参数
var correct_type; //小题类型
var mp3s=[];  //记录音频数组
for(i=0;i<problems.length;i++){
    mp3s.push(null);
}

var problem_resource; //题目的最外层元素
var questions_resource; //小题列表最外层元素
var question_resource; //单个小题细节最外层元素
//  TYPES = {0 => "n.", 1 => "v.", 2 => "pron.", 3 => "adj.", 4 => "adv.",
//    5 => "num.", 6 => "art.", 7 => "prep.", 8 => "conj.", 9 => "interj.", 10 => "u = ", 11 => "c = ", 12 => "pl = "}
var word_type = {
    "0":"n.",
    "1":"v.",
    "2":"pron.",
    "3":"adj.",
    "4":"adv.",
    "5":"num.",
    "6":"art.",
    "7":"prep.",
    "8":"conj.",
    "9":"interj.",
    "10":"u = ",
    "11":"c = ",
    "12":"pl = "
} ; //单词类型

$(function(){
    $.ajax({
        type: "POST",
        url: "/similarities/ajax_load_sheets.json",
        dataType: "json",
        data : {
            "sheet_url" : sheet_url
        },
        success : function(data) {
            clearTimeout(load_time);
            if(data["message"]){
                tishi_alert(data["message"]);
            }
            sheet = data["sheet"];
            init_paper();
        }
    });
})

function init_paper(){
    $("#generate").empty();
    if(sheet!=null){
        init_problem = parseInt(sheet["init"]);
    }
    finish_index = init_problem;
    $("#global_problem_sum").html(problems.length);
    $("#global_problem_index").html(init_problem+1);
    load_problem(init_problem);
}


function load_problem(problem_index){
    has_drag = false;
    drag_attrs=[];
    problem_resource = create_element("div",null,null,"problem_resource",null,"innerHTML");
    $(problem_resource).attr("name",init_problem);
    if(finish_index<=init_problem){
        $("#generate").append(problem_resource);
    }else{
        $("#generate").prepend(problem_resource);
    }
    left_side(); //左边，大题描述，大题标题，音频，以及题面内小题的处理
    right_side(); //右边，小题列表，各类小题的细节
    if(mp3){
        clone_flowplayer(("#flowplayer_location_"+init_problem),mp3);
        mp3s[init_problem]=mp3;
        mp3=null;
    }
    //main_height(); //控制页面的高度
    pro_qu_t(init_problem); //小题列表展开关闭功能
    check_answer(init_problem); //载入存储的答案
    afterload(); //其它需要的细节
    tooltip();
    finish_index = init_problem;
}


function check_answer(problem_index){
    for(i=0;i<problems[problem_index].questions.question.length;i++){
        if(sheet!=null && sheet["_"+problem_index+"_"+i]){
            $("#refer_btn_"+problem_index+"_"+i).trigger("click");
        }
    }

}

function afterload(){
    // 拖选框，预留高度
    if($("#drag_tk_"+init_problem).length>0){
        var m_side_width = $("#m_side_"+init_problem).width();
        $("#draggable_list_"+init_problem).css("width",m_side_width-20);
        var drag_tk_height = $("#draggable_list_"+init_problem).height();
        var m_side_height = $("#m_side_"+init_problem).height();
        var pbl_height = m_side_height-drag_tk_height-40;//padding的高度
        $("#problem_box_"+init_problem).css("height",pbl_height);
        $("#drag_tk_"+init_problem).css("height",drag_tk_height);
    $("#draggable_list_"+init_problem).css("top",34+$("#m_side_"+init_problem).height()-$("#drag_tk_"+init_problem).height());
    }
    if(problems[init_problem].question_type!="1"){
        $("#pro_qu_t_"+init_problem+"_0").trigger("click");
    }
}

//鼠标移动提示
function tooltip(){
    var x = -20;
    var y = 15;
    $(".tooltip_"+init_problem).mouseover(function(e){
        var tooltip = "<div class='tooltip_box'><div class='tooltip_next'>"+$(this).attr("name")+"</div></div>";
        $("body").append(tooltip);
        $(".tooltip_box").css({
            "top":(e.pageY+y)+"px",
            "left":(e.pageX+x)+"px"
        }).show("fast");
    }).mouseout(function(){
        $(".tooltip_box").remove();
    }).mousemove(function(e){
        $(".tooltip_box").css({
            "top":(e.pageY+y)+"px",
            "left":(e.pageX+x)+"px"
        })
    });
}

function left_side(){
    element1 = create_element("div",null,"m_side_"+init_problem,"m_side m_problem_bg",null,"innerHTML");
    $(problem_resource).append(element1);
    element2 = create_element("div",null,"problem_box_"+init_problem,"problem_box",null,"innerHTML");
    $(element1).append(element2);
    element3 = create_element("div",null,"flowplayer_location_"+init_problem,null,null,"innerHTML");
    $(element2).append(element3);
    element1 = create_element("div",null,null,"question_explain",null,"innerHTML");
    if(problems[init_problem].description){
        element1.innerHTML="<p><em>"+problems[init_problem].description+"</em></p>";
    }
    $(element2).append(element1);
    element1 = create_element("div",null,null,"problem_text",null,"innerHTML");
    element1.innerHTML=problem_title();
    $(element2).append(element1);
    element1 = create_element("div",null,null,null,null,"innerHTML");
    $(element1).attr("style","height:20px;");
    $(element2).append(element1);
    if(has_drag){
        $(element2).addClass("tuozhuai_box");
        element1 = create_element("div",null,"drag_tk_"+init_problem,"drag_tk border_radius",null,"innerHTML");
        $("#m_side_"+init_problem).append(element1);
        element3 = create_element("ul",null,"draggable_list_"+init_problem,null,null,"innerHTML");
        $(element1).append(element3);
        element3.innerHTML+="<div><span class='red'>*</span>拖选下面的单词到相应的答案位置。</div>";
        drag_attrs = drag_attrs.sort();
        str1="";
        for(i=0;i<drag_attrs.length;i++){
            str1 += "<li name='"+drag_attrs[i]+"' class='draggable_attr_"+init_problem+"'>"+drag_attrs[i]+"</li>"
        }
        element3.innerHTML+=(str1);
        for(i=0;i<problems[init_problem].questions.question.length;i++){
            $("#droppable_"+init_problem+"_"+i).droppable({
                drop: function( event, ui ) {
                    $(this).html(ui.draggable.attr("name"));
                    $("#exam_user_answer_"+init_problem+"_"+($(this).attr("id").split("_")[2])).val(ui.draggable.attr("name"));
                }
            });
        }
        $(".draggable_attr_"+init_problem).draggable({
            helper: "clone"
        });
    }
}

function right_side(){
    element1 = create_element("div",null,null,"m_side",null,"innerHTML");
    $(problem_resource).append(element1);
    element2 = create_element("div",null,null,"problem_box",null,"innerHTML");
    $(element1).append(element2);
    if(problems[init_problem]["question_type"]=="1"){
        element3 = create_element("div",null,"tk_zuoda_"+init_problem,"tk_zuoda",null,"innerHTML");
        $(element3).html("请在左侧作答!");
        $(element2).append(element3);
    }
    questions_resource = element2;
    for(q=0;q<problems[init_problem].questions.question.length;q++){
        question_box(questions_resource,q);
    }

}

//右边单个小题
function question_box(questions_resource,question_index){
    correct_type=problems[init_problem].questions.question[question_index].correct_type;
    element1 = create_element("div",null,null,"pro_question_list border_rb p_q_line pro_question_list_"+init_problem,null,"innerHTML");
    $(questions_resource).append(element1);
    if(problems[init_problem]["question_type"]=="1"){
        $(element1).css("display","none");
    }
    element2 = create_element("div",null,null,"pql_left",null,"innerHTML");
    $(element1).append(element2);
    element3 = create_element("div",null,"color_flag_"+init_problem+"_"+question_index,"un_white",null,"innerHTML");
    $(element2).append(element3);
    element3 = create_element("span",null,null,"icon_shoucang",null,"innerHTML");
    $(element2).append(element3);
    if(collection == "" || collection == [] || collection.indexOf(problems[init_problem].questions.question[question_index]["id"])==-1){
        if(problems[init_problem]["question_type"]==null || problems[init_problem]["question_type"]=="0"){
            $(element3).html("<a href='javascript:void(0);' id='shoucang_"+problems[init_problem].questions.question[question_index]["id"]+"' class='tooltip tooltip_"+init_problem+"' name='收藏' onclick=\"javascript:normal_add_collect('"+init_problem+"','"+question_index+"');\">收藏</a>");
        }
        else{
            $(element3).html("<a href='javascript:void(0);' id='shoucang_"+problems[init_problem].questions.question[question_index]["id"]+"' class='tooltip tooltip_"+init_problem+"' name='收藏' onclick=\"javascript:special_add_collect('"+init_problem+"','"+question_index+"');\">收藏</a>");
        }
    }else{
        $(element3).html("<a href='javascript:void(0);' id='shoucang_"+problems[init_problem].questions.question[question_index]["id"]+"' class='tooltip tooltip_"+init_problem+" hover' name='已收藏'>收藏</a>");
    }

    element2 = create_element("div",null,null,"pql_right",null,"innerHTML");
    $(element1).append(element2);
    element3 = create_element("div",null,"pro_qu_t_"+init_problem+"_"+question_index,"pro_qu_t pro_qu_t_"+init_problem,null,"innerHTML");
    $(element3).attr("name",question_index);
    $(element2).append(element3);
    if(problems[init_problem]["question_type"]==null || problems[init_problem]["question_type"]=="0"){
        element1 = create_element("div",null,null,"question_tx",null,"innerHTML");
        $(element1).html(q_type[correct_type]);
        $(element3).append(element1);
    }
    if(problems[init_problem].questions.question[question_index]["description"]&&problems[init_problem].questions.question[question_index]["description"]!=""){
        element1 = create_element("div",null,null,"pro_t_con",null,"innerHTML");
        $(element1).html(problems[init_problem].questions.question[question_index]["description"]);
    }else{
        element1 = create_element("div",null,"replace_description_span_"+init_problem+"_"+question_index,"replace_description_span",null,"innerHTML");
    }
    $(element3).append(element1);
    element3 = create_element("input",null,"exam_user_answer_"+init_problem+"_"+question_index,"exam_user_answer","hidden","");
    $(element2).append(element3);
    element3 = create_element("input",null,"pass_check_"+init_problem+"_"+question_index,"pass_check","hidden","");
    $(element2).append(element3);
    element3 = create_element("div",null,"red_cuo_"+init_problem+"_"+question_index,"red_cuo",null,"innerHTML");
    $(element3).css("display","none");
    $(element3).html("<img src='/assets/red_cuo.png'>");
    $(element2).append(element3);
    element3 = create_element("div",null,"green_dui_"+init_problem+"_"+question_index,"green_dui",null,"innerHTML");
    $(element3).css("display","none");
    $(element3).html("<img src='/assets/green_dui.png'>");
    $(element2).append(element3);
    element3 = create_element("div",null,null,"pro_qu_div",null,"innerHTML");
    $(element3).css("display","none");
    $(element2).append(element3);
    question_resource = element3;
    if(problems[init_problem]["question_type"]==null || problems[init_problem]["question_type"]=="0"){
        outter_question(question_index);
    }
    element1 =  create_element("div",null,null,"pro_btn",null,"innerHTML");
    $(question_resource).append(element1);
    if(problems[init_problem]["question_type"]==null || problems[init_problem]["question_type"]=="0"){
        element2 =  create_element("button",null,"refer_btn_"+init_problem+"_"+question_index,null,null,"innerHTML");
        $(element2).css("display","none");
        $(element2).attr("onclick","javascript:refer_question('0','"+problems[init_problem].questions.question[question_index].correct_type+"',"+init_problem+","+question_index+");");
        $(element1).append(element2);
        element2 =  create_element("button",null,"check_question_btn_"+init_problem+"_"+question_index,"t_btn",null,"innerHTML");
        $(element2).attr("onclick","javascript:check_question('0','"+problems[init_problem].questions.question[question_index].correct_type+"',"+init_problem+","+question_index+");");
        $(element2).html("核对");
        $(element1).append(element2);
        element2 =  create_element("button",null,"next_question_btn_"+init_problem+"_"+question_index,"t_btn",null,"innerHTML");
        $(element2).attr("onclick","javascript:do_next_question("+init_problem+","+question_index+");");
        $(element2).css("display","none");
        $(element2).html("下一题");
        $(element1).append(element2);
    }
    $(element1).html($(element1).html()+"<a href='javascript:void(0);' class=\"upErrorTo_btn\" onclick=\"javascript:open_report_error('"+problems[init_problem].questions.question[question_index]["id"]+"');\">报告错误</a>");
    if(problems[init_problem].questions.question[question_index]["words"]!=null && problems[init_problem].questions.question[question_index]["words"]!=""){
        $(element1).html($(element1).html()+"<button class=\"t_btn\" onclick=\"javascript:ajax_load_about_words('"+problems[init_problem].questions.question[question_index]["words"]+"',"+init_problem+","+question_index+");\">相关词汇</button>");
    }
    element1 = create_element("div",null,"display_jiexi_"+init_problem+"_"+question_index,"jiexi",null,"innerHTML");
    $(element1).css("display","none");
    $(question_resource).append(element1);
    element2 = create_element("div",null,null,null,null,"innerHTML");
    $(element1).append(element2);
    $(element2).html("正确答案：");
    element3 = create_element("span",null,"display_answer_"+init_problem+"_"+question_index,"red",null,"innerHTML");
    $(element3).html(answers[init_problem][question_index].answer);
    $(element2).append(element3);
    element2 = create_element("div",null,"display_analysis_"+init_problem+"_"+question_index,null,null,"innerHTML");
    $(element2).html(answers[init_problem][question_index].analysis);
    $(element1).append(element2);
    element1 = create_element("div",null,"about_words_position_"+init_problem+"_"+question_index,null,null,"innerHTML");
    $(question_resource).append(element1);
    $(element1).html("<input type='hidden' value='' id='about_words_resource_"+init_problem+"_"+question_index+"'></input>");
}

//题面中小题细节
function inner_question(correct_type,question_index){
    str1 = "<span class='span_tk' id='inner_span_tk_"+init_problem+"_"+question_index+"' onmouseover='javascript:show_hedui("+init_problem+","+question_index+");' onmouseout='javascript:hide_hedui("+init_problem+","+question_index+");'>";
    switch(correct_type){
        case "0":{
            str1 += "<span onmouseout=\"javascript:close_select_ul(event,this,"+init_problem+","+question_index+");\">";
            str1 += "<span class='select_span inner_borde_blue_"+init_problem+"_"+question_index+"' id='input_inner_answer_"+init_problem+"_"+question_index+"' onclick='javascript:toggle_select_ul("+init_problem+","+question_index+");'></span>";
            str1 += "<span class='select_ul select_ul_"+init_problem+"' id='select_ul_"+init_problem+"_"+question_index+"' style='display:none;'>";
            question_attrs = store3[question_index].questionattrs.split(";-;");
            for(j=0;j<question_attrs.length;j++){
                str1 += "<span class='select_li select_li_"+init_problem+"_"+question_index+"' onclick=\"javascript:do_inner_select('"+question_attrs[j]+"',"+init_problem+","+question_index+");\">"+question_attrs[j]+"</span>";
            };
            str1 += "</span>";
            str1 += "</span>";
            break;
        }
        case "1":{
            has_drag=true;
            question_attrs = store3[question_index].questionattrs.split(";-;");
            for(j=0;j<question_attrs.length;j++){
                drag_attrs.push(question_attrs[j]);
            }
            str1 += "<span class='dragDrop_box inner_borde_blue_"+init_problem+"_"+question_index+"' id='droppable_"+init_problem+"_"+question_index+"'></span>";
            break;
        }
        case "3":{
            str1 += "<input class='input_tk inner_borde_blue_"+init_problem+"_"+question_index+"' type='text' id='input_inner_answer_"+init_problem+"_"+question_index+"' onkeydown='call_me("+init_problem+","+question_index+");' onchange='javascript:do_inner_question(3,"+init_problem+","+question_index+");'></input>";
            break;
        }

    }
    str1 += "<span class='button_span' style='display:none;' ><button id='hedui_btn_"+init_problem+"_"+question_index+"' class='button_tk' onclick = \"javascript:check_question('1',"+correct_type+","+init_problem+","+question_index+");\">核对</button></span>";
    str1 += "</span>";
    str1 += "<button style='display:none;' id='refer_btn_"+init_problem+"_"+question_index+"' onclick = \"javascript:refer_question('1','"+correct_type+"',"+init_problem+","+question_index+");\">更新</button>";
    return str1;
}

// 题面后小题细节
function outter_question(question_index){
    element1 = create_element("div",null,null,"pro_qu_ul",null,"innerHTML");
    $(question_resource).append(element1);
    element2 = create_element("ul",null,null,null,null,"innerHTML");
    $(element1).append(element2);
    switch(correct_type){
        case "0":{
            question_attrs = problems[init_problem].questions.question[question_index].questionattrs.split(";-;");
            for(i=0;i<question_attrs.length;i++){
                element3 = create_element("li",null,null,null,null,"innerHTML");
                $(element2).append(element3);
                store1 = create_element("span",null,null,"single_choose_li single_choose_li_"+init_problem+"_"+question_index,null,"innerHTML");
                $(store1).attr("onclick","javascript:do_single_choose(this,"+init_problem+","+question_index+");");
                attr = question_attrs[i].split(")");
                if(attr.length>1){
                    sign = attr[0];
                    attr.shift();
                    content = attr.join("");
                }else{
                    sign = "";
                    content = attr[0];
                }
                $(store1).html(sign);
                $(element3).append(store1);
                store2 = create_element("p",null,null,null,null,"innerHTML");
                $(store2).html(content);
                $(element3).append(store2);
            }
            break;
        }
        case "1":{
            question_attrs = problems[init_problem].questions.question[question_index].questionattrs.split(";-;");
            for(i=0;i<question_attrs.length;i++){
                element3 = create_element("li",null,null,null,null,"innerHTML");
                $(element2).append(element3);
                store1 = create_element("span",null,null,"multi_choose_li multi_choose_li_"+init_problem+"_"+question_index,null,"innerHTML");
                $(store1).attr("onclick","javascript:do_multi_choose(this,"+init_problem+","+question_index+");");
                attr = question_attrs[i].split(")");
                if(attr.length>1){
                    sign = attr[0];
                    attr.shift();
                    content = attr.join("");
                }else{
                    sign = "";
                    content = attr[0];
                }
                $(store1).html(sign);
                $(element3).append(store1);
                store2 = create_element("p",null,null,null,null,"innerHTML");
                $(store2).html(content);
                $(element3).append(store2);
            }
            break;
        }
        case "2":{
            element3 = create_element("li",null,null,null,null,"innerHTML");
            $(element2).append(element3);
            store1 = create_element("span",null,null,"single_choose_li judge_li_"+init_problem+"_"+question_index,null,"innerHTML");
            $(store1).attr("onclick","javascript:do_judge(this,'1',"+init_problem+","+question_index+");");
            $(element3).append(store1);
            store2 = create_element("p",null,null,null,null,"innerHTML");
            $(store2).html("对/是");
            $(element3).append(store2);
            element3 = create_element("li",null,null,null,null,"innerHTML");
            $(element2).append(element3);
            store1 = create_element("span",null,null,"single_choose_li judge_li_"+init_problem+"_"+question_index,null,"innerHTML");
            $(store1).attr("onclick","javascript:do_judge(this,'0',"+init_problem+","+question_index+");");
            $(element3).append(store1);
            store2 = create_element("p",null,null,null,null,"innerHTML");
            $(store2).html("错/否");
            $(element3).append(store2);
            break;
        }
        case "3":{
            element3 = create_element("input",null,"fill_input_"+init_problem+"_"+question_index,"input_xz","text","");
            $(element3).attr("onchange","javascript:do_fill_blank(this,this.value,"+init_problem+","+question_index+")");
            $(element2).append(element3);
            break;
        }
        case "5":{
            element3 = create_element("textarea",null,"fill_input_"+init_problem+"_"+question_index,"textarea_xz1",null,"");
            $(element3).attr("onchange","javascript:do_fill_blank(this,this.value,"+init_problem+","+question_index+")");
            $(element2).append(element3);
            break;
        }
    }
}

//处理题面标题
function problem_title(){
    var problem_title = problems[init_problem].title;
    store1 = problem_title.split("((mp3))");
    if(store1.length>1){
        mp3 = store1[1];
        problem_title = store1[0]+store1[2];
    }
    if(problems[init_problem].question_type=="1"){
        store1 = problem_title.split("((sign))");
        store2=[];
        store3=problems[init_problem].questions.question;
        for(i=0;i<store3.length;i++){
            store2.push(inner_question(store3[i].correct_type,i));
        }
        problem_title="";
        for(i=0;i<store2.length;i++){
            problem_title += (store1[i]+store2[i]);
        }
        problem_title += store1[store2.length];
    }
    return problem_title;
}


function main_height(){
    var win_height = $(window).height();
    var head_height = $(".head").height();
    var mainTop_height = $(".m_top").height();
    var foot_height = $(".foot").height();
    var main_height = win_height-(head_height+mainTop_height+foot_height);
    $(".m_side").css('height',main_height-12);//12为head的padding的12px
    $(".main").css('height',main_height-12+34);//34是m_top的高度，
}

//generate.js  end




