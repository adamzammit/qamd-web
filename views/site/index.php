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
            <div class="col-lg-6">
                <h2>About</h2>

                <p><a href="https://github.com/Raymanns/qamd">QAMyData</a> is a data quality assurance tool for SPSS, STATA and SAS files. <a href="https://github.com/adamzammit/qamd-web">qamd-web</a> is a web front end, running on the Yii2 framework in a Docker container for easy access to the tool.</p>

            </div>
        </div>

    </div>
</div>
