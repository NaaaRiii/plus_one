document.addEventListener("turbo:load", function() {
  // 1. カウンター変数counterの初期値を動的に設定
  let counter = $("#small-goals-container > div").length;

  $("#add-small-goal").click(function() {
    console.log('Add button was clicked!');
    counter++;
    let smallGoalField = `
      <div id="small-goal-${counter}">
        <label for="goal_small_goals_attributes_${counter}_content">Small goal</label>
        <input type="text" name="goal[small_goals_attributes][${counter}][content]" id="goal_small_goals_attributes_${counter}_content" class="goal-small_goal">
      </div>
    `;
    $("#small-goals-container").append(smallGoalField);
  });

  $("#remove-small-goal").click(function() {
    if($("#small-goals-container > div").length > 0 ) {
      $("#small-goals-container > div:last-child").remove();
      // 3. counterの値をデクリメントせず、単純にインクリメントし続ける
      // counter--; この行を削除
    }
  });
});