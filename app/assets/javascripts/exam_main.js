
//tooltip提示
$(function(){
    var x = -20;
    var y = 15;
    $(".tooltip").mouseover(function(e){
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
})

//提示框样式设定
function generate_flash_div(style) {
    var scolltop = document.body.scrollTop|document.documentElement.scrollTop;
    var win_height = document.documentElement.clientHeight;//jQuery(document).height();
    var win_width = jQuery(window).width();
    var z_layer_height = jQuery(style).height();
    var z_layer_width = jQuery(style).width();
    jQuery(style).css('top',250);
    jQuery(style).css('left',(win_width-z_layer_width)/2);
    jQuery(style).css('display','block');
}

//提示框弹出层
function show_flash_div() {
    $('.tishi_tab').stop();
    generate_flash_div(".tishi_tab");
    $('.tishi_tab').delay(5500).fadeTo("slow",0,function(){
        $(this).remove();
    });
}

//创建元素
function create_element(element, name, id, class_name, type, ele_flag) {
    var ele = document.createElement("" + element);
    if (name != null)
        ele.name = name;
    if (id != null)
        ele.id = id;
    if (class_name != null)
        ele.className = class_name;
    if (type != null)
        ele.type = type;
    if (ele_flag == "innerHTML") {
        ele.innerHTML = "";
    }
    else {
        ele.value = ele_flag;
    }
    return ele;
}

//弹出错误提示框
function tishi_alert(str){
    var div = create_element("div",null,"flash_notice","tishi_tab border_radius",null,null);
    div.innerHTML+="<span class='xx_x' onclick='javascript:close_tishi_tab();'><img src='/assets/xx.png' /></span>";
    var p = create_element("p","","","","innerHTML");
    p.innerHTML = str;
    div.appendChild(p);
    var body = jQuery("body");
    body.append(div);
    show_flash_div();
}

//关闭提示框
function close_tishi_tab(){
    $(".tishi_tab").remove();
}

function AutoScroll(obj){
    $(obj).find("ul:first").animate({
        marginTop:"-25px"
    },500,function(){
        $(this).css({
            marginTop:"0px"
        }).find("li:first").appendTo(this);
    });
}


  Array.prototype.indexOf=function(el, index){
    var n = this.length>>>0, i = ~~index;
    if(i < 0) i += n;
    for(; i < n; i++) if(i in this && this[i] === el) return i;
    return -1;
  }


