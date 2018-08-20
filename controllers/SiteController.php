<?php

namespace app\controllers;

use Yii;
use yii\filters\AccessControl;
use yii\web\Controller;
use yii\web\Response;
use yii\filters\VerbFilter;
use app\models\LoginForm;
use app\models\ContactForm;
use app\models\UploadForm;
use yii\web\UploadedFile;



class SiteController extends Controller
{
    /**
     * {@inheritdoc}
     */
    public function actions()
    {
        return [
            'error' => [
                'class' => 'yii\web\ErrorAction',
            ],
            'captcha' => [
                'class' => 'yii\captcha\CaptchaAction',
                'fixedVerifyCode' => YII_ENV_TEST ? 'testme' : null,
            ],
        ];
    }

    /**
     * Displays homepage.
     *
     * @return string
     */
    public function actionIndex()
    {
        $model = new UploadForm();

        if (Yii::$app->request->isPost) {
            $model->file = UploadedFile::getInstance($model, 'file');
            if (is_array($return = $model->upload())) {
                // file is uploaded successfully
				//execute qamd and display output to user
                $webpath = realpath(dirname(__FILE__).'/../web') . "/" . $return["key"] . "/";
				mkdir($webpath);
                exec("qamd -l -p -o " . $webpath . "index.html --output-format html " . $return["path"] . $return["file"]);
				//remove temporary files
				unlink($return["path"] . $return["file"]);
				rmdir($return["path"]);
                return $this->redirect("/" . $return["key"]);
            }
        }

        return $this->render('index', ['model' => $model]);
    }

}
