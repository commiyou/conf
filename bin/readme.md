# Shell 命令入门

本文档旨在介绍一些在我们的开发环境中常用的 Shell 命令，以帮助新同事更快地熟悉我们的工作流程。

## 基础命令

### `cat`

`cat` 是一个基础命令，用于显示文件内容。它经常与管道符 `|` 结合使用，将文件内容传递给其他命令进行处理。

**常见用法:**

- **显示文件内容:**

  ```shell
  cat /etc/centos-release
  ```

- **将文件内容通过管道传递给其他命令:**

  ```shell
  cat cluster.v3.tsv | awk '$3=="[]"' | head -1
  cat cluster.v3.tsv | awk '$3=="[]"' | head -1 | cut -f4 | pp
  ```

- **与 `grep` 结合使用进行内容过滤:**
  ```shell
  cat q_card_pv.20241220 | grep "僭"
  ```

## 自定义脚本

### `addcol`

为文件的每一行添加指定数量的列。

**常见用法:**

- **为每行添加一个空列:**
  ```shell
  cat file.txt | addcol
  ```
- **为每行添加两列，值为 "new_value":**
  ```shell
  cat file.txt | addcol -n 2 -v "new_value"
  ```

### `csbk`

根据键对数据进行聚合操作 (column sum by key)。
默认情况下:

- 如果指定了值列 (`-v`)，则同时计算**计数 (count)** 和**求和 (sum)**。
- 如果未指定值列，则仅计算**计数 (count)**。

**常见用法:**

- **根据第1和第2列作为键，对第3列计算计数和总和:**
  ```shell
  csbk -k0,1 -v2 data.tsv > data.sum
  ```
- **统计第1列中每个键出现的次数:**
  ```shell
  csbk -k0 data.tsv
  ```
- **获取所有聚合统计信息 (sum, count, avg, min, max):**
  ```shell
  csbk -k0 -v2 -A data.tsv
  ```

### `dedup`

根据指定的键去除文件中的重复行。

**常见用法:**

- **根据整行内容去重:**
  ```shell
  cat file.txt | dedup
  ```
- **根据第一列去重:**
  ```shell
  cat file.txt | dedup -k 0
  ```

### `divide`

对文件中的列进行除法运算。

**常见用法:**

- **计算第1列除以第2列的结果:**
  ```shell
  cat data.tsv | divide -p 0,1
  ```
- **计算第1列占该列总和的百分比:**
  ```shell
  cat data.tsv | divide -p 0 -P
  ```

### `duh`

以易于阅读的格式显示磁盘使用情况。

**常见用法:**

- **查看当前目录的磁盘使用情况:**
  ```shell
  duh
  ```

### `each`

遍历文件路径并对每个文件执行脚本。

**常见用法:**

- **打印当前目录下每个文件的文件名:**
  ```shell
  ls | each 'echo $f'
  ```

### `fno`

快速查看文件某行的内容及其字段构成 (Field Number Output)。

**常见用法:**

- **查看文件第一行的内容:**

  ```shell
  fno cluster.tsv
  ```

- **查看文件第4行的内容 (行号从0开始):**
  ```shell
  fno q_parse_res.top1.20241220 -l 3
  ```
- **随机查看一行内容:**
  ```shell
  fno q_parse_res.top1.20241220 -r
  ```
- **将首行作为表头:**
  ```shell
  fno -h cluster.tsv
  ```
- **使用表达式过滤行:**

  ```shell
  # 筛选第3个字段(索引为2)等于'value'的行
  fno -e '$2=="value"' data.tsv

  # 筛选第1个字段包含'pattern'的行 (如果pattern为全小写，则忽略大小写)
  fno -e '$0~/pattern/' data.tsv
  ```

### `insert`

在文件的每一行指定位置插入新列。

**常见用法:**

- **在每行末尾插入一个 "-":**
  ```shell
  cat file.txt | insert
  ```
- **在第一列前插入 "prefix":**
  ```shell
  cat file.txt | insert -i 0 -p "prefix"
  ```
- **根据另一个文件中的键值进行插入 (类似 join):**
  ```shell
  insert -f key_value.txt -K 0 file_to_insert.txt
  ```

### `ocr`

对屏幕截图进行 OCR 文字识别，并将结果复制到剪贴板。

**常见用法:**

- **启动截图并识别:**
  ```shell
  ocr
  ```

### `pp` & `ppl`

格式化并高亮输出 JSON 数据。`pp` 处理单个JSON对象，`ppl` 处理每行一个JSON对象的流。

**常见用法:**

- **格式化一个JSON文件:**
  ```shell
  cat data.json | pp
  ```
- **格式化多行JSON数据:**
  ```shell
  cat data.jsonl | ppl
  ```

### `slbk`

根据一个文件中的键，筛选另一个文件中的行 (select line by key)。这是一个非常强大的工具，可以看作是针对结构化文本文件的 `grep`。

**常见用法:**

- **基础筛选:**
  筛选出 `data.tsv` 中，第一列的值存在于 `keys.txt` 中的行。

  ```shell
  slbk -f keys.txt -K 0 data.tsv
  ```

- **反向筛选:**
  选择 `data.tsv` 中，第一列的值不存在于 `keys.txt` 中的行。

  ```shell
  slbk -f keys.txt -K 0 -r data.tsv
  ```

- **多列匹配与不同分隔符:**
  筛选 `data.csv` 中第2和第4列组成的键，该键需要匹配 `keys.csv` 中第1和第2列组成的键。两个文件都使用逗号作为分隔符。

  ```shell
  slbk -f keys.csv -k 1,2 -K 2,4 -d ',' -D ',' data.csv
  ```

- **处理不同文件编码:**
  假设 `keys.txt` 是 `gbk` 编码，而 `data.log` 是 `utf-8` 编码，进行筛选。

  ```shell
  slbk -f keys.txt -e gbk -E utf-8 data.log
  ```

- **忽略大小写和HTTP前缀:**
  在匹配时忽略大小写，并去除键中的 `http://` 或 `https://` 前缀。
  ```shell
  slbk -f urls_to_find.txt -i -H access.log
  ```

### `xltool`

用于操作 Excel 文件的命令行工具，基于 `fire` 提供了多个子命令。

**常见用法:**

- **列出所有工作表 (包括隐藏的):**

  ```shell
  xltool list-sheets data.xlsx
  ```

- **列出工作表并预览每张表的前5行:**

  ```shell
  xltool list-sheets data.xlsx --n 5
  ```

- **将指定工作表转换为 TSV 格式:**
  默认转换第一个工作表 (索引为0)，并输出到标准输出。

  ```shell
  xltool convert-to-tsv data.xlsx
  ```

- **转换指定名称的工作表并保存到文件:**
  ```shell
  xltool convert-to-tsv data.xlsx --sheet_name "Sheet2" --output_tsv_path output.tsv
  ```

**重要说明:**

- 在转换过程中，单元格内的换行符 (`\n`, `\r`) 会被替换为空格。
- 输出的 TSV 文件不使用任何引号包裹字段 (`quoting=csv.QUOTE_NONE`)，这对于后续使用 `awk`, `cut` 等工具处理非常重要。

### `yank`

将文件内容或标准输入复制到系统剪贴板，在 `tmux` 环境下尤其有用。

**常见用法:**

- **复制文件内容:**
  ```shell
  yank file.txt
  ```
- **复制命令输出:**
  ```shell
  grep "error" log.txt | yank
  ```

### iterm2 utils

see `https://iterm2.com/documentation-utilities.html`

## 总结

熟悉这些命令将有助于您更高效地在我们的开发环境中工作。如果您对某个命令有疑问，可以随时向您的同事请教。
