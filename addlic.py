import os

def add_license_to_file(file_path, license_text, check_text):
    """向文件开头添加 license 信息"""
    with open(file_path, 'r+', encoding='utf-8') as file:
        content = file.read()
        if check_text in content:
            print(f"License already present in {file_path}, skipping.")
            return False  # 跳过已经存在的文件
        file.seek(0)
        file.write(license_text + '\n' + content)
    print(f"Added license to {file_path}")
    return True

def process_directory(directory, extensions, license_text, check_text):
    """
    遍历目录中的指定后缀文件，添加 license 信息
    :param directory: 要遍历的目录路径
    :param extensions: 指定的文件后缀，例如 ['.py', '.java']
    :param license_text: 要添加的 license 信息
    :param check_text: 用于判断 license 是否存在的关键字
    """
    for root, _, files in os.walk(directory):
        for file in files:
            if any(file.endswith(ext) for ext in extensions):
                file_path = os.path.join(root, file)
                add_license_to_file(file_path, license_text, check_text)

if __name__ == '__main__':
    # 配置项
    directory_to_scan = './'  # 项目根目录
    file_extensions = ['.v', '.cpp']  # 需要处理的文件后缀
    license_text = """
/*                                                                      
Designer   : Renyangang               
                                                                        
Licensed under the Apache License, Version 2.0 (the "License");         
you may not use this file except in compliance with the License.        
You may obtain a copy of the License at                                 
                                                                        
    http://www.apache.org/licenses/LICENSE-2.0                          
                                                                        
Unless required by applicable law or agreed to in writing, software    
distributed under the License is distributed on an "AS IS" BASIS,       
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and     
limitations under the License. 
*/
"""
    check_text = "Designer   : Renyangang"  # 判断是否已包含的关键文本

    # 执行处理
    process_directory(directory_to_scan, file_extensions, license_text, check_text)
