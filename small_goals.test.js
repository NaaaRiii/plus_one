//// Import the code you want to test
//const smallGoals = require('./app/javascript/small_goals');

//// Mock the jQuery selector
//const $ = require('jquery');
//global.$ = global.jQuery = $;

//describe('smallGoals', () => {
//  // Test the add-task button click event
//  describe('add-task button', () => {
//    test('should add a new task field to the tasks-container', () => {
//      // Set up the initial state of the DOM
//      document.body.innerHTML = `
//        <div id="tasks-container">
//          <div id="task-1">
//            <label for="small_goal_tasks_attributes_1_content">Task</label>
//            <input type="text" name="small_goal[tasks_attributes][1][content]" id="small_goal_tasks_attributes_1_content" class="task-content">
//          </div>
//        </div>
//        <button id="add-task">Add Task</button>
//      `;

//      // Simulate a click on the add-task button
//      $('#add-task').trigger('click');

//      // Expect that a new task field was added to the tasks-container
//      expect($('#tasks-container > div').length).toBe(2);
//    });
//  });

//  // Test the remove-task button click event
//  describe('remove-task button', () => {
//    test('should remove the last task field from the tasks-container', () => {
//      // Set up the initial state of the DOM
//      document.body.innerHTML = `
//        <div id="tasks-container">
//          <div id="task-1">
//            <label for="small_goal_tasks_attributes_1_content">Task</label>
//            <input type="text" name="small_goal[tasks_attributes][1][content]" id="small_goal_tasks_attributes_1_content" class="task-content">
//          </div>
//          <div id="task-2">
//            <label for="small_goal_tasks_attributes_2_content">Task</label>
//            <input type="text" name="small_goal[tasks_attributes][2][content]" id="small_goal_tasks_attributes_2_content" class="task-content">
//          </div>
//        </div>
//        <button id="remove-task">Remove Task</button>
//      `;

//      // Simulate a click on the remove-task button
//      $('#remove-task').trigger('click');

//      // Expect that the last task field was removed from the tasks-container
//      expect($('#tasks-container > div').length).toBe(1);
//      expect($('#tasks-container > div:last-child').attr('id')).toBe('task-1');
//    });
//  });
//});


//describe('add-task button', () => {
//  test('should add a new task field to the tasks-container', () => {
//    document.body.innerHTML = `
//      <div id="tasks-container">
//        <div id="task-1">
//          <label for="small_goal_tasks_attributes_1_content">Task</label>
//          <input type="text" name="small_goal[tasks_attributes][1][content]" id="small_goal_tasks_attributes_1_content" class="task-content">
//        </div>
//      </div>
//      <button id="add-task">Add Task</button>
//    `;

//    $('#add-task').trigger('click');
//    expect($('#tasks-container > div').length).toBe(1);
//  });
//});

//describe('remove-task button', () => {
//  test('should remove the last task field from the tasks-container', () => {
//    document.body.innerHTML = `
//      <div id="tasks-container">
//        <div id="task-1">
//          <label for="small_goal_tasks_attributes_1_content">Task</label>
//          <input type="text" name="small_goal[tasks_attributes][1][content]" id="small_goal_tasks_attributes_1_content" class="task-content">
//        </div>
//        <div id="task-2">
//          <label for="small_goal_tasks_attributes_2_content">Task</label>
//          <input type="text" name="small_goal[tasks_attributes][2][content]" id="small_goal_tasks_attributes_2_content" class="task-content">
//        </div>
//      </div>
//      <button id="remove-task">Remove Task</button>
//    `;

//    $('#remove-task').trigger('click');
//    expect($('#tasks-container > div').length).toBe(2);
//  });
//});

import { setupTaskButtons } from './app/javascript/small_goals.js';

describe('Task Buttons', () => {
  beforeEach(() => {
    // DOMのセットアップ
    document.body.innerHTML = `
      <div id="tasks-container"></div>
      <button id="add-task">Add Task</button>
      <button id="remove-task">Remove Task</button>
    `;

    // イベントハンドラのセットアップ
    setupTaskButtons();
  });

  test('adds a task field when add-task button is clicked', () => {
    $('#add-task').click();
    expect($('#tasks-container > div').length).toBe(1);
  });

  test('removes the last task field when remove-task button is clicked', () => {
    // 最初にタスクを追加
    $('#add-task').click();
    $('#add-task').click(); // 2つのタスクがある状態

    // 1つのタスクを削除
    $('#remove-task').click();
    expect($('#tasks-container > div').length).toBe(1);
  });
});