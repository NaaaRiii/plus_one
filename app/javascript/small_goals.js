//document.addEventListener("turbo:load", function() {
//  let counter = $("#tasks-container > div").length;
//  console.log('JavaScriptが読み込まれました。');
//  $("#add-task").click(function() {
//    console.log('Add task button was clicked!');
//    counter++;
//    let taskField = `
//      <div id="task-${counter}">
//        <label for="small_goal_tasks_attributes_${counter}_content">Task</label>
//        <input type="text" name="small_goal[tasks_attributes][${counter}][content]" id="small_goal_tasks_attributes_${counter}_content" class="task-content">
//      </div>
//    `;
//    $("#tasks-container").append(taskField);
//  });

//  $("#remove-task").click(function() {
//    if($("#tasks-container > div").length > 0) {
//      $("#tasks-container > div:last-child").remove();
//    }
//  });
//});

export function setupTaskButtons() {
  const addTaskButton = document.querySelector('#add-task');
  const removeTaskButton = document.querySelector('#remove-task');
  const tasksContainer = document.querySelector('#tasks-container');

  if (!addTaskButton || !removeTaskButton || !tasksContainer) {
    console.error('Error: One of the task buttons or the tasks container was not found.');
    return;
  }

  addTaskButton.addEventListener('click', function() {
    const counter = tasksContainer.querySelectorAll('div').length + 1;
    const taskField = `
      <div id="task-${counter}">
        <label for="small_goal_tasks_attributes_${counter}_content">Task</label>
        <input type="text" name="small_goal[tasks_attributes][${counter}][content]" id="small_goal_tasks_attributes_${counter}_content" class="task-content">
      </div>
    `;
    tasksContainer.insertAdjacentHTML('beforeend', taskField);
  });

  removeTaskButton.addEventListener('click', function() {
    const lastTaskField = tasksContainer.querySelector('div:last-child');
    if (lastTaskField) {
      lastTaskField.remove();
    }
  });
}


document.addEventListener("turbo:load", function() {
  let counter = $("#tasks-container > div").length;
  console.log('JavaScriptが読み込まれました。');

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
      counter = $("#tasks-container > div").length; // タスクが削除されるたびに counter を更新
    }
  });
});
