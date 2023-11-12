document.addEventListener('turbo:load', function() {
  console.log('turbo:load event triggered - setting up event listeners');
  // タスクのチェックボックスにイベントリスナーを設定
  const taskCheckboxes = document.querySelectorAll('.task-checkbox');
  console.log(`Found ${taskCheckboxes.length} task checkboxes.`); // チェックボックスの数を出力

  taskCheckboxes.forEach(function(checkbox, index) {
    console.log(`Setting up change listener for checkbox ${index + 1}.`); // イベントリスナー設定のログ
    checkbox.addEventListener('change', function() {
      console.log(`Checkbox ${index + 1} changed. Checking completion status.`); // チェックボックスが変更されたことをログに出力
      const smallGoalId = checkbox.dataset.smallGoalId;
      if (!smallGoalId) {
        console.error('Error: No smallGoalId found for this checkbox.'); // smallGoalIdがない場合のエラーログ
        return;
      }

      const smallGoalDiv = document.querySelector(`div[data-small-goal-id="${smallGoalId}"]`);
      if (!smallGoalDiv) {
        console.error(`Error: No .small-goal div found for smallGoalId ${smallGoalId}.`); // 対応する.small-goal divがない場合のエラーログ
        return;
      }

      const allTaskCheckboxes = smallGoalDiv.querySelectorAll('.task-checkbox');
      console.log(`There are ${allTaskCheckboxes.length} checkboxes in this small goal.`); // small goal内のチェックボックス数をログに出力
      const allCompleted = Array.from(allTaskCheckboxes).every(chk => chk.checked);
      console.log(`All tasks completed: ${allCompleted}`); // すべてのタスクが完了しているかのログ

      // すべてのタスクが完了している場合は、完了ボタンを表示
      const smallGoalCompleteButton = smallGoalDiv.querySelector('.small-goal-complete-button');
      if (!smallGoalCompleteButton) {
        console.error('Error: No .small-goal-complete-button found.'); // 完了ボタンがない場合のエラーログ
        return;
      }

      if (allCompleted) {
        console.log('All tasks are completed. Showing the complete button.'); // すべて完了していれば完了ボタンを表示するログ
        smallGoalCompleteButton.style.display = 'block';
      } else {
        console.log('Not all tasks are completed. Hiding the complete button.'); // すべて完了していなければ完了ボタンを非表示にするログ
        smallGoalCompleteButton.style.display = 'none';
      }
    });
  });
});
