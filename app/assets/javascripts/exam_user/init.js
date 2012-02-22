//此JS进行试卷初始化，处理试卷和答案数据

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
                b1[j].questions =  transform_array(b1[j].questions.question);
                problems.push(b1[j]);
            }
        }
    }
}
//alert(JSON.encode(problems));
$(function(){
    //写入总题数
    $("#global_problem_sum").html(problems.length);
})





