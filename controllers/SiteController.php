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
                exec("qamd run -p -o " . $webpath . "index.html --output-format html " . $return["path"] . $return["file"]);
                //if index.html failed to generate - generate error page
                if (!file_exists($webpath . "index.html")) {
                    file_put_contents($webpath . "index.html"," <!DOCTYPE html><html><head><meta charset=\"UTF-8\"><title>Error</title></head><body><p>There was an error processing {$return["file"]}</p></body></html>");
                }
                //rewrite index.html to point to local files
                $index = file_get_contents($webpath . "index.html");
                $find = array("https://stackpath.bootstrapcdn.com/bootstrap/4.1.1/js/bootstrap.min.js",
                            "https://code.jquery.com/jquery-3.3.1.slim.min.js",
                            "https://cdnjs.cloudflare.com/ajax/libs/popper.js/1.14.3/umd/popper.min.js",
                            "https://stackpath.bootstrapcdn.com/bootstrap/4.1.1/css/bootstrap.min.css");
                $replace = array("../js/bootstrap.min.js",
                    "../js/jquery-3.3.1.slim.min.js",
                    "../js/popper.min.js",
                    "../css/bootstrap.min.css");
                $index = str_replace($find,$replace,$index);
                file_put_contents($webpath . "index.html",$index);
				//remove temporary files
				unlink($return["path"] . $return["file"]);
				rmdir($return["path"]);
                return $this->redirect("/" . $return["key"]);
            }
        }

        return $this->render('index', ['model' => $model]);
    }

}
