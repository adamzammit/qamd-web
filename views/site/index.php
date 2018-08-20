<?php
use yii\widgets\ActiveForm;
use kartik\file\FileInput;

/* @var $this yii\web\View */

$this->title = 'Web frontend for QAMyData Tool';
?>
<div class="site-index">

    <div class="jumbotron">
        <h1>Web frontend for <a href='https://github.com/Raymanns/qamd'>QAMyData</a> tool</h1>

        <p class="lead">Select an SPSS, STATA or SAS data file to upload to begin</p>

<?php $form = ActiveForm::begin(['options' => ['enctype' => 'multipart/form-data']]) ?>

    <?= $form->field($model, 'file')->widget(FileInput::classname()) ?>

    <button class="btn btn-lg btn-success">Upload</button>

<?php ActiveForm::end() ?>

    </div>

    <div class="body-content">

        <div class="row">
            <div class="col-lg-4">
                <h2>About</h2>

                <p>QAMyData is a dta quality assurance tool for SPSS, STATA and SAS files. qamd-web is a web front end, running on the Yii2 framework for this tool</p>

            </div>
        </div>

    </div>
</div>
