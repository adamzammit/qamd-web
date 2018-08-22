<?php

namespace app\models;

use Yii;
use yii\base\Model;
use yii\web\UploadedFile;

class UploadForm extends Model
{
    public $file;

    public function rules()
    {
        return [
            [['file'],'file','skipOnEmpty' => false, 'extensions' => 'sav,dta,sas,por,ss2,lst,sd2,sv2,si2,sc2,sa2,sf2,sm2,su2,sp2,stx,sas7bpgm,sas7baud,sas7bdat,sas7bvew,sas7bdnx,sas7bcat,sas7bacs,sas7bfdb,sas7bmdb,sas7bdmd,sas7bitm,sas7butl,sas7bput,sas7bbak,ss7,st7,sd7,sv7,si7,sc7,sa7,sf7,sm7,s7m,sr7,su7,sp7', 'checkExtensionByMimeType' => false],
        ];
    }

    public function upload()
    {
        if ($this->validate()) {
            //create a random dir and save to a file with a cleaned filename
            $baseName = preg_replace('/[^A-Za-z0-9\_]/', '_', $this->file->baseName); // Replace all non alpha/numbers with underscores
            $baseName = substr($baseName,0,200); //restrict to 200 chars
            $fname = $baseName . "." . $this->file->extension; //return extension to aid processing
			$key = Yii::$app->getSecurity()->generateRandomString(); //create a random path to put it
            $uploadpath = realpath(dirname(__FILE__).'/../uploads') . "/" . $key . "/";
            if (mkdir($uploadpath)) {
	            if ($this->file->saveAs($uploadpath . $fname)) {
					return ["path" => $uploadpath, "file" => $fname, "key" => $key];
				}
            }
        }
		return false;
   }
}
