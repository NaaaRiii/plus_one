document.addEventListener("turbo:load", function() {
  let counter = $("#tasks-container > div").length;

  $("#add-task").click(function() {
    console.log('Add task button was clicked!');
    counter++;
    let taskField = `
      <div id="task-${counter}">
        <label for="small_goal_tasks_attributes_${counter}_content">Task</label>
        <input type="text" name="small_goal[tasks_attributes][${counter}][content]" id="small_goal_tasks_attributes_${counter}_content" class="task-content">
      </div>
    `;
    $("#tasks-container").append(taskField);
  });

  $("#remove-task").click(function() {
    if($("#tasks-container > div").length > 0) {
      $("#tasks-container > div:last-child").remove();
    }
  });
});
