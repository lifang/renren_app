//此js用于生成考试页面元素

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


$(function(){
    $.ajax({
        type: "POST",
        url: "/similarities/ajax_load_sheets.json",
        dataType: "json",
        data : {
            "sheet_url" : sheet_url
        },
        success : function(data) {
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
    main_height(); //控制页面的高度
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
        var tooltip = "<div class='tooltip_box'><div class='tooltip_next'>"+this.name+"</div></div>";
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
        drag_attrs = drag_attrs.sort();
        str1="";
        for(i=0;i<drag_attrs.length;i++){
            str1 += "<li name='"+drag_attrs[i]+"' class='draggable_attr_"+init_problem+"'>"+drag_attrs[i]+"</li>"
        }
        $(element3).html(str1);
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
        }else{
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
            str1 += "<span class='select_span inner_borde_blue_"+init_problem+"_"+question_index+"' id='input_inner_answer_"+init_problem+"_"+question_index+"' onclick='javascript:toggle_select_ul("+init_problem+","+question_index+");'></span>";
            str1 += "<span class='select_ul select_ul_"+init_problem+"' id='select_ul_"+init_problem+"_"+question_index+"' style='display:none;' onmouseover=\"javascript:$(this).css('display', 'block');\" onmouseout=\"javascript:$(this).css('display', 'none');close_select_ul("+init_problem+","+question_index+");\">";
            question_attrs = store3[question_index].questionattrs.split(";-;");
            for(j=0;j<question_attrs.length;j++){
                str1 += "<span class='select_li select_li_"+init_problem+"_"+question_index+"' onclick=\"javascript:do_inner_select('"+question_attrs[j]+"',"+init_problem+","+question_index+");\">"+question_attrs[j]+"</span>";
            };
            str1 += "</span>";
            break;
        }
        case "1":{
            has_drag=true;
            question_attrs = store3[question_index].questionattrs.split(";-;");
            for(j=0;j<question_attrs.length;j++){
                drag_attrs.push(question_attrs[j]);
            }
            str1 += "<span class='dragDrop_box inner_backg_blue_"+init_problem+"_"+question_index+"' id='droppable_"+init_problem+"_"+question_index+"'></span>";
            break;
        }
        case "3":{
            str1 += "<input class='input_tk inner_backg_blue_"+init_problem+"_"+question_index+"' type='text' id='input_inner_answer_"+init_problem+"_"+question_index+"' onkeydown='call_me("+init_problem+","+question_index+");' onchange='javascript:do_inner_question(3,"+init_problem+","+question_index+");'></input>";
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

