import 'dart:ffi';
import 'dart:math';
import 'dart:typed_data';

import 'lz_crc.dart';

///这是 专门处理数据的工具类

class LZDataUtil {
  //1. 十进制 转16进制
  Future<dynamic> intToHex(int data) async {
    String hexStr = data.toRadixString(16);

    return hexStr;
  }

  //2. 16 进制字符串转 int
  Future<dynamic> hexStrToInt(String data) async {
    //16进制一定要去除前缀"0x"
    int dataInt = int.parse(data, radix: 16);

    return dataInt;
  }

  //3. 16 进制数字 转为 double 小数
  Future<dynamic> hexToDouble(int num) async {
    var bdata = ByteData(4);

    bdata.setInt32(0, num);

    var doubleValue = bdata.getFloat32(0);

    return doubleValue;
  }

  //4. 十进制  double 小数  转16进制
  Future<dynamic> doubleToHex(double num) async {
    ByteData bdata = ByteData(8);

    bdata.setFloat32(0, num);

    int fbits = bdata.getInt32(0);

    String hexStr = fbits.toRadixString(16);

    return hexStr;
  }

  //5.  16 进制字符串转为 10进制
  Future<dynamic> hexToInt(String hex) async {
    int val = 0;
    int len = hex.length;
    for (int i = 0; i < len; i++) {
      int hexDigit = hex.codeUnitAt(i);
      if (hexDigit >= 48 && hexDigit <= 57) {
        val += (hexDigit - 48) * (1 << (4 * (len - 1 - i)));
      } else if (hexDigit >= 65 && hexDigit <= 70) {
        // A..F
        val += (hexDigit - 55) * (1 << (4 * (len - 1 - i)));
      } else if (hexDigit >= 97 && hexDigit <= 102) {
        // a..f
        val += (hexDigit - 87) * (1 << (4 * (len - 1 - i)));
      } else {
        throw new FormatException("Invalid hexadecimal value");
      }
    }
    return val;
  }

  ///6. 十六进制数组转换为十进制
  Future<dynamic> listToFloat() async {
    Uint8List uint8list = Uint8List.fromList([2, 0, 255, 62, 76, 204, 204, 1]);

    Uint8List subList = Uint8List.sublistView(uint8list, 3, 7);

    Uint8List resultList = Uint8List.fromList(subList);

    ByteData byteData = ByteData.view(resultList.buffer);

    int result = byteData.getInt32(0);

    return result;
  }

  ///7. 十六进制数组 转换为 字符串
  String uint8ToHex(List<int> dataList) {
    if (dataList == null || dataList.length == 0) {
      return "";
    }

    Uint8List byteArr = Uint8List.fromList(dataList);

    Uint8List result = Uint8List(byteArr.length << 1);
    var hexTable = [
      '0',
      '1',
      '2',
      '3',
      '4',
      '5',
      '6',
      '7',
      '8',
      '9',
      'A',
      'B',
      'C',
      'D',
      'E',
      'F'
    ]; //16进制字符表
    for (var i = 0; i < byteArr.length; i++) {
      var bit = byteArr[i]; //取传入的byteArr的每一位
      var index = bit >> 4 & 15; //右移4位,取剩下四位
      var i2 = i << 1; //byteArr的每一位对应结果的两位,所以对于结果的操作位数要乘2
      result[i2] = hexTable[index].codeUnitAt(0); //左边的值取字符表,转为Unicode放进resut数组
      index = bit & 15; //取右边四位
      result[i2 + 1] =
          hexTable[index].codeUnitAt(0); //右边的值取字符表,转为Unicode放进resut数组
    }

    return '0x${String.fromCharCodes(result)}';
  }

  ///8. 数组逆序
  Future<dynamic> listInverted(List dataList) async {
    for (int min = 0, max = dataList.length - 1; min < max; min++, max--) {
      //对数组中的元素,进行位置交换
      //min索引和max索引的元素交换
      //定义变量,保存min索引
      int temp = dataList[min];
      //max索引上的元素,赋值给min索引
      dataList[min] = dataList[max];
      //临时变量,保存的数据,赋值到max索引上
      dataList[max] = temp;
    }

    return dataList;
  }

  //9.最终的统一方法

  ///十六进制数组转换为字符串
  ///读取蓝牙的数据，进行处理
  Future<dynamic> readListToStr(List dataList) async {
    //数组逆序
    var sortList = await LZDataUtil().listInverted(dataList);

    //十六进制数组 转换为 字符串
    String str = LZDataUtil().uint8ToHex(sortList);

    //字符串转 10 进制
    int numData = int.parse(str);

    //16 进制转 double 小数
    var doubleValue = await LZDataUtil().hexToDouble(numData);

    return doubleValue;
  }

  //10.字符串反转
  Future<dynamic> reverseStr(String dataStr) async {
    var chars = dataStr.runes.toList();
    return String.fromCharCodes(chars.reversed);
  }

  //11.字符串 按2位分割成数组
  Future<dynamic> strToList(String dataStr) async {
    List<String> strList = [];
    if (dataStr.length <= 2) {
      strList.add(dataStr);
    } else {
      int splitCount = dataStr.length ~/ 2; //应该切割的次数
      for (int i = 0; i < splitCount; i++) {
        strList.add(dataStr.substring(2 * i, 2 * (i + 1)));
      }

      ///截取方式  0-2  2-4  4-6
      if (dataStr.length % 2 != 0) {
        //字符串长度为奇数位
        //奇数位最后肯定还会剩一个 比如abcde spliteCount为2  最后剩下一个e
        strList.add(dataStr.substring(2 * splitCount));
      }
    }
    // print('strList:  ${strList.toString()}');

    return strList;
  }

  ///12. 十六进制数组 转换为十进制数组
  Future<dynamic> hexListToInt(List dataList) async {
    List intList = [];

    for (var item in dataList) {
      int dataInt = int.parse(item, radix: 16);

      intList.add(dataInt);
    }

    return intList;
  }

  ///13. 十进制数组 转换为 十六进制数组
  Future<dynamic> intListToHex(List dataList) async {
    List hexList = [];

    for (var item in dataList) {
      String hexStr = item.toRadixString(16);

      hexList.add(hexStr);
    }

    return hexList;
  }

  //14.蓝牙发送的数据， CRC 32 校验，生成数组
  Future<List<int>> sendListData(List dataList) async {
    //CRC 32 校验
    int crc32 = LZCrcUtil().checkSum(dataList, 16);

    //int 转 16 进制字符串
    String hexStr = await LZDataUtil().intToHex(crc32);

    //字符串按 2 位分割为数组
    List strList = await LZDataUtil().strToList(hexStr);

    // print('0x16 CRC 校验 strList  =============================== $strList');

    //16 进制数组转 10 进制
    List intList = await LZDataUtil().hexListToInt(strList);

    //数组逆序
    List sortList = await LZDataUtil().listInverted(intList);

    //强制转换
    //强制类型转换
    List<int> resultList = List<int>.from(sortList.whereType<int>());

    return resultList;
  }

  //17.蓝牙发送数据，double 转成 16 进制数组

  Future<List<int>> doubleToList(double sendData) async {
    //十进制  double 小数  转16进制
    var hexStr = await LZDataUtil().doubleToHex(sendData);

    //字符串按 2 位分割为数组
    List strList = await LZDataUtil().strToList(hexStr);

    //16 进制数组转 10 进制
    List intList = await LZDataUtil().hexListToInt(strList);

    //数组逆序
    List sortList = await LZDataUtil().listInverted(intList);

    //强制类型转换
    List<int> resultList = List<int>.from(sortList.whereType<int>());

    return resultList;
  }

  double bitsToDouble22222(int bits) {
    Uint8List list = _int32bytes333333(bits);
    ByteBuffer buffer = new Int8List.fromList(list.reversed.toList()).buffer;
    ByteData byteData = new ByteData.view(buffer);
    double result = byteData.getFloat32(0);
    return result;
  }

  //19. 十六进制转换为字符串

  Future<String> hexListToStr(List<int> dataList) async {
    String res = "";
    for (var i = 0; i < dataList.length; i++) {
      res += String.fromCharCode(int.parse(dataList[i].toRadixString(10)));
    }

    return res;
  }

  Uint8List ieee754HpBytesFromDouble(double fval) {
    int result = _doubleToBits(fval);

    Uint8List beef = _int32bytes333333(result);

    Uint8List res = Uint8List.fromList(beef.reversed.skip(2).toList());

    return Uint8List.fromList(beef.reversed.skip(2).toList());
  }

  Uint8List _int32bytes333333(int value) =>
      Uint8List(4)..buffer.asInt32List()[0] = value;

  ///
  /// Double to hp-float bits
  ///
  int _doubleToBits(double fval) {
    ByteData bdata = ByteData(8);
    bdata.setFloat32(0, fval);
    int fbits = bdata.getInt32(0);

    int sign = fbits >> 16 & 0x8000;
    int val = (fbits & 0x7fffffff) + 0x1000;

    if (val >= 0x47800000) {
      if ((fbits & 0x7fffffff) >= 0x47800000) {
        if (val < 0x7f800000) return sign | 0x7c00;
        return sign | 0x7c00 | (fbits & 0x007fffff) >> 13;
      }
      return sign | 0x7bff;
    }
    if (val >= 0x38800000) return sign | val - 0x38000000 >> 13;
    if (val < 0x33000000) return sign;
    val = (fbits & 0x7fffffff) >> 23;
    return sign |
        ((fbits & 0x7fffff | 0x800000) + (0x800000 >> val - 102) >> 126 - val);
  }

  double ieee754HpBytesToDouble(List<int> i) {
    int hbits = i[0] * 256 + i[1];
    int mant = hbits & 0x03ff;
    int exp = hbits & 0x7c00;
    if (exp == 0x7c00)
      exp = 0x3fc00;
    else if (exp != 0) {
      exp += 0x1c000;
      if (mant == 0 && exp > 0x1c400) {
        return _bitsToDouble((hbits & 0x8000) << 16 | exp << 13 | 0x3ff);
      }
    } else if (mant != 0) {
      exp = 0x1c400;
      do {
        mant <<= 1;
        exp -= 0x400;
      } while ((mant & 0x400) == 0);
      mant &= 0x3ff;
    }

    double toDouble =
        _bitsToDouble((hbits & 0x8000) << 16 | (exp | mant) << 13);

    return _bitsToDouble((hbits & 0x8000) << 16 | (exp | mant) << 13);
  }

  double _bitsToDouble(int bits) {
    Uint8List list = _int32bytes333333(bits);
    ByteBuffer buffer = new Int8List.fromList(list.reversed.toList()).buffer;
    ByteData byteData = new ByteData.view(buffer);
    double result = byteData.getFloat32(0);
    return result;
  }
}
