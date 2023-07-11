import shutil
import os

remove_section_dict = {'CARE_2D_DL4Mic': '1.1. 1.2. 2. 6.3.',
                    'CARE_3D_DL4Mic': '1.1. 1.2. 2. 6.2.',
                    'CycleGAN_DL4Mic': '2. 6.3.',
                    'Deep-STORM_2D_DL4Mic': '2. 6.4.',
                    'Noise2Void_2D_DL4Mic': '1.1. 1.2. 2. 6.3.',
                    'Noise2Void_3D_DL4Mic': '1.1. 1.2. 2. 6.2.',
                    'StarDist_2D_DL4Mic': '1.1. 1.2. 2. 6.3.',
                    'StarDist_3D_DL4Mic': '1.1. 1.2. 2. 6.2.',
                    'U-Net_2D_Multilabel_DL4Mic': '1.1. 1.2. 2. 6.2.',
                    'U-Net_2D_DL4Mic': '1.1. 1.2. 2. 6.3.',
                    'U-Net_3D_DL4Mic': '1.1. 1.2. 2. 6.2.',
                    'YOLOv2_DL4Mic': '1.1. 1.2. 2. 6.3.',
                    'fnet_2D_DL4Mic': '1.1. 1.2. 2. 6.3.',
                    'fnet_3D_DL4Mic': '1.1. 1.2. 2. 6.3.',
                    'pix2pix_DL4Mic': '2. 6.3.'
                    }
def main():
    notebook_list = ['CARE_2D_DL4Mic', 'CARE_3D_DL4Mic', 'CycleGAN_DL4Mic', 'Deep-STORM_2D_DL4Mic', 'Noise2Void_2D_DL4Mic', 'Noise2Void_3D_DL4Mic', 'StarDist_2D_DL4Mic', 'StarDist_3D_DL4Mic', 'U-Net_2D_DL4Mic', 'U-Net_2D_Multilabel_DL4Mic', 'U-Net_3D_DL4Mic', 'YOLOv2_DL4Mic', 'fnet_2D_DL4Mic', 'fnet_3D_DL4Mic', 'pix2pix_DL4Mic']
    template_dockerfile_path = os.path.join("./notebooks", "template", "Dockerfile")
    template_bash_path = os.path.join("./notebooks", "template", "docker.sh")

    for notebook_name in notebook_list:
        print(notebook_name)
        notebook_path = os.path.join("./notebooks", notebook_name)
        os.makedirs(notebook_path, exist_ok=True)
        shutil.copy(template_dockerfile_path, os.path.join(notebook_path,  "Dockerfile"))
        print(u'\t\u2713 Dockerfile has been copied.')
        shutil.copy(template_bash_path, os.path.join(notebook_path,  "docker.sh"))
        print(u'\t\u2713 docker.sh has been copied.')

        file=open(os.path.join(notebook_path,  "sections_to_remove.txt"),'w')
        file.writelines(f'{remove_section_dict[notebook_name]}')
        file.close()

if __name__ == "__main__":
    main()