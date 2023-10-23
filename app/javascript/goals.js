$(document).ready(function() {
  let counter = 1;

  $("#add-small-goal").click(function() {
    console.log('Add button was clicked!');
    counter++;
    //let smallGoalField = `
    //  <div id="small-goal-${counter}">
    //    <label for="small_goal">Small goal</label>
    //    <input type="text" name="small_goal[]" class="goal-small_goal">
    //  </div>
    //`;
    let smallGoalField = `
      <div id="small-goal-${counter}">
        <label for="goal_small_goals_attributes_${counter}_content">Small goal</label>
        <input type="text" name="goal[small_goals_attributes][${counter}][content]" class="goal-small_goal">
      </div>
    `;
    $("#small-goals-container").append(smallGoalField);
  });

  $("#remove-small-goal").click(function() {
    if(counter > 1) {
      $("#small-goal-" + counter).remove();
      counter--;
    }
  });
});



