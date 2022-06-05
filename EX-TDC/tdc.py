import torch
from torch import nn
import math
import numpy as np
import argparse

#求卷积核大小
def Kc_size( Kd, s):
    No = (int(Kd / 2)) / s
    if((No - int(No))<1/2):
         Kc = 2 * int(No) + 1
    else:
         Kc = 2 * (int(No)+1)
    return(Kc)

# 分割权值矩阵/从1变成s^2,N输出通道数，M输入通道数
def kernal_s2(M,N,Kd, s, Kc, Wd):
    Wc = np.zeros((M,N * s * s, Kc, Kc))
    newtensor =np.empty((s*s,Kc,Kc),dtype='S20')
    print(Wc.shape)
    for m in range(M):
        for n in range(N):
            for Xi in range(Kc):
                for Yi in range(Kc):
                    for Xo in range(s):
                        for Yo in range(s):
                            No = (int(Kd / 2)) / s
                            if ((No - int(No)) < 1 / 2):
                                Xr = Kd - (s * Xi)
                                Yr = Kd - (s * Yi)
                                Xr0=Kd
                            else:
                                Xr = Kd - (s * Xi) + 1
                                Yr = Kd - (s * Yi) + 1
                                Xr0=Kd+1
                            Xd = Xr - (s - (Xo % s))
                            Yd = Yr - (s - (Yo % s))
                            if (0 <= Xd < Kd and 0 <= Yd < Kd):
                                Wc[m, n* s * s + s * Yo + Xo, Yi, Xi] = Wd[m, n, Yd, Xd]
                                if(m==0):
                                    a='({},{})'.format(Yd,Xd)
                                    newtensor[s * Yo + Xo,Yi, Xi]=a
                            else:
                                if (m== 0):
                                    newtensor[s * Yo + Xo,Yi, Xi] = '  0  '

    return(Wc,Xr0, newtensor)

#求卷积的padding
def Kc_padding(a,b,Xr,s):
    c1=math.ceil((a+args.padding-Xr)/s)-(b-Kc)
    c2=math.ceil((Xr-s-args.padding)/s)
    if c1>c2:
        padding=c1
    else:
        padding=c2
    return(padding)

def Kc_padding_end():
    a= Kc_padding(output_size_row, input_size_row, Xr, args.scale)
    b= Kc_padding(output_size_col, input_size_col, Xr, args.scale)
    if a>b:
        padding=a
    else:
        padding=b
    return(padding)

#模型参数输入
if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--Kd', type=int, required=True)
    parser.add_argument('--scale', type=int, required=True)
    parser.add_argument('--padding', type=int, required=True)
    parser.add_argument('--output_padding', type=int, required=True)
    parser.add_argument('--weights-file', type=str, required=True)
    parser.add_argument('--image-file', type=str, required=True)
    args = parser.parse_args()

#计算TDC方法所需参数
Wd=torch.load(args.weights_file,map_location=torch.device('cpu')).to(torch.float32)
Win=torch.load(args.image_file,map_location=torch.device('cpu')).to(torch.float32)
# Win=np.delete(Win,(np.s_[-5:-1]),axis=2)
# Win=np.delete(Win,(np.s_[0:3]),axis=3)
M=((Wd.numpy()).shape)[0]
N=((Wd.numpy()).shape)[1]
Kc=Kc_size(args.Kd, args.scale)
Xc,Xr,WcIdx= kernal_s2(M,N,args.Kd,args.scale,Kc,Wd)
Xc = Xc.transpose((1, 0, 2, 3))
torch.save(Xc, "weight_TDC")
input_size_row=(Win.shape)[2]
input_size_col=(Win.shape)[3]
output_size_row=(input_size_row - 1) * args.scale + args.Kd - 2*args.padding + args.output_padding
output_size_col=(input_size_col - 1) * args.scale + args.Kd - 2*args.padding + args.output_padding
Kc_padding=Kc_padding_end()
over1_row=(Kc_padding+input_size_row-Kc)*args.scale-(output_size_row+args.padding-Xr)
over1_col=(Kc_padding+input_size_col-Kc)*args.scale-(output_size_col+args.padding-Xr)
over2_row=Kc_padding*args.scale-(Xr-args.padding-args.scale)
over2_col=Kc_padding*args.scale-(Xr-args.padding-args.scale)

#验证
# 卷积求结果
model1=nn.Conv2d(in_channels=M,out_channels=N*args.scale*args.scale,kernel_size=Kc,stride=1,padding=Kc_padding)
model1.weight.data=torch.from_numpy(Xc).to(torch.float32)
model1.bias.data = torch.zeros(N*args.scale*args.scale)
ps=nn.PixelShuffle(args.scale)
output=ps(model1(Win)).detach().numpy()
output_size_end_row=output.shape[2]
output_size_end_col=output.shape[3]
output1=np.delete(output,(np.s_[-1-over1_row:-1]),axis=2)
output2=np.delete(output1,(np.s_[-1-over1_col:-1]),axis=3)
output3=np.delete(output2,(np.s_[0:over2_row]),axis=2)
output_end=np.delete(output3,(np.s_[0:over2_col]),axis=3)

# 反卷积函数直接求结果
model=nn.ConvTranspose2d(in_channels=M, out_channels=N, kernel_size=args.Kd,stride=args.scale,padding=args.padding,output_padding=args.output_padding)
model.weight.data =Wd
model.bias.data = torch.zeros(N)
output_orignal=(model(Win)).detach().numpy()

#比较TDC输出和反卷积函数直接输出是否相同
compare_result=(output_end==output_orignal).any()

#TDC参数输出
print("卷积核大小:{}".format(Kc))
print("\n卷积时的padding:{}".format(Kc_padding))
print("\ndel row:",end="")
for i in range(over2_row):
 print(i,end=" ")
for i in range(output_size_end_row-over1_row+1,output_size_end_row+1):
 print(i, end=" ")
print("\ndel col:",end="")
for i in range(over2_col):
 print(i,end=" ")
for i in range(output_size_end_col-over1_col+1,output_size_end_col+1):
 print(i, end=" ")
print()
# print("\n权重转换示意图\n",WcIdx)
print("\n输入特征图:{}".format(args.image_file))
print("\nTDC方法处理后得到的权值矩阵：weight_TDC\n")
if(compare_result==1):
  print("验证后，结果比对成功")
else:
  print("验证后，结果比对失败")
print("\n权重转换示意图:")
for i in range(args.scale*args.scale):
    print("输出像素=({},{})".format(int(i/args.scale),i%args.scale))
    for i in WcIdx[i]:
      print("-------------------------------")
      print(end="|")
      for j in i:
        print(j.decode(),end="|")
      print()
    print("-------------------------------\n")
