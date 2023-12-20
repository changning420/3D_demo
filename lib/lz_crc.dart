



import 'dart:ffi';
import 'dart:math';
import 'dart:typed_data';
import 'dart:convert';





class LZCrcUtil {

  int poly_nomial_value = 0xA669FCA3;   /*多项式初始值*/
  int init_value= 0x376CF428;    /*初始值*/
  int xor_value= 0x21DB82BF;    /*结果异或值*/

  var  crc_table_32;

  ///初始化
  void initCrc(){

    // crc_table_32 = Uint8List(256);

    crc_table_32 = Uint32List(256);

    if(crc_table_32 == null){


    }else{

      crc32_init(poly_nomial_value);

    }

  }



  crc32_init(int poly_init_val){

    int i, j;
    int cal_value;

    poly_init_val  = bit_rev(poly_init_val, 32);

    for (i = 0; i < 256; i++)
    {
      cal_value = i;
      for (j = 0; j < 8; j++)
      {
        if (cal_value & 0x01 == 1 )
        {
          cal_value = poly_init_val ^ (cal_value >> 1);
        }
        else
        {
          cal_value = cal_value >> 1;
        }
      }
      crc_table_32[i] = cal_value;


    }



  }


  int bit_rev(int input, int bit_width ){


    int i;
    int ret_val = 0;

    for (i = 0; i < bit_width; i++)
    {
      if (input & 0x01 == 1)
      {
        ret_val |= 1 << (bit_width - i - 1);
      }
      input = input >> 1;
    }
    return ret_val;



  }




  int checkSum(var input, int len ){

    //初始化
    initCrc();

    int check_sum = init_value;//设置初始值 可自定义初始值

    int index;

    int i = 0;

    while (len-- != 0)
    {
      index = (check_sum ^ input[i]) & 0xFf;

      check_sum = (check_sum >> 8) ^ crc_table_32[index];

      check_sum = check_sum & 0xFFFFFFFF;

      i++;



    }

    /*异或 可自定义异或值*/
    check_sum ^= xor_value;

    return check_sum;



  }




}




