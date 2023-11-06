//document.addEventListener('turbo:load', function() {
//  // タスクのチェックボックスにイベントリスナーを設定
//  const taskCheckboxes = document.querySelectorAll('.task-checkbox');
//  taskCheckboxes.forEach(function(checkbox) {
//    checkbox.addEventListener('change', function() {
//      const smallGoalId = checkbox.dataset.smallGoalId;
//      const smallGoalDiv = document.querySelector(`div[data-small-goal-id="${smallGoalId}"]`);
//      const allTaskCheckboxes = smallGoalDiv.querySelectorAll('.task-checkbox');
//      const allCompleted = Array.from(allTaskCheckboxes).every(chk => chk.checked);

//      // すべてのタスクが完了している場合は、Small goalのチェックボックスを表示
//      const smallGoalCheckboxDiv = smallGoalDiv.querySelector('.small-goal-checkbox');
//      if (allCompleted) {
//        smallGoalCheckboxDiv.style.display = 'block';
//      } else {
//        smallGoalCheckboxDiv.style.display = 'none';
//      }
//    });
//  });
//});

document.addEventListener('turbo:load', function() {
  // タスクのチェックボックスにイベントリスナーを設定
  const taskCheckboxes = document.querySelectorAll('.task-checkbox');
  taskCheckboxes.forEach(function(checkbox) {
    checkbox.addEventListener('change', function() {
      const smallGoalId = checkbox.dataset.smallGoalId;
      const smallGoalDiv = document.querySelector(`div[data-small-goal-id="${smallGoalId}"]`);
      const allTaskCheckboxes = smallGoalDiv.querySelectorAll('.task-checkbox');
      const allCompleted = Array.from(allTaskCheckboxes).every(chk => chk.checked);

      // すべてのタスクが完了している場合は、完了ボタンを表示
      const smallGoalCompleteButton = smallGoalDiv.querySelector('.small-goal-complete-button');
      if (allCompleted) {
        smallGoalCompleteButton.style.display = 'block';
      } else {
        smallGoalCompleteButton.style.display = 'none';
      }
    });
  });
});
