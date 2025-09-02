import csv
import xlrd
import os

if __name__=='__main__':

    data_dir="/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/coded_eeg/6m"
    for file in os.listdir(data_dir):
        if file.endswith(".xlsx") or file.endswith(".xlsm"):
            (fname,ext)=os.path.splitext(file)
            subj_id=fname[0:3]
            out_dir=os.path.join('/data/infant_gaze_eeg/6m/raw/',subj_id,'EEG')
            workbook = xlrd.open_workbook(os.path.join(data_dir,file))
            for idx,sheet in enumerate(workbook.sheets()):
                fout_name=os.path.join(out_dir,'%s-movementcoding.csv' % fname)
                if idx>0:
                    if sheet.row_values(0)[0]=='Movements':
                        continue
                    fout_name=os.path.join(out_dir,'%s-initialdirectioncoding.csv' % fname)
                f=open(fout_name,'wb')
                writer = csv.writer(f)
                writer.writerows(sheet.row_values(row) for row in range(sheet.nrows))
                f.close()

    data_dir="/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/coded_eeg/9m"
    for file in os.listdir(data_dir):
        if file.endswith(".xlsx") or file.endswith(".xlsm"):
            (fname,ext)=os.path.splitext(file)
            subj_id=fname[0:3]
            out_dir=os.path.join('/data/infant_gaze_eeg/9m/raw/',subj_id,'EEG')
            workbook = xlrd.open_workbook(os.path.join(data_dir,file))
            for idx,sheet in enumerate(workbook.sheets()):
                fout_name=os.path.join(out_dir,'%s-movementcoding.csv' % fname)
                if idx>0:
                    if sheet.row_values(0)[0]=='Movements':
                        continue
                    fout_name=os.path.join(out_dir,'%s-initialdirectioncoding.csv' % fname)
                f=open(fout_name,'wb')
                writer = csv.writer(f)
                writer.writerows(sheet.row_values(row) for row in range(sheet.nrows))
                f.close()