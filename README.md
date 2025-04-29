# mc-ryodan-client-bat

mc-ryodanサーバでのMCクライアントのMOD環境などのセットアップ方法  
windows環境を想定  

- MODなど必要なリソースを取得
- MODローダを実行してインストールしてもらう
- 起動構成を作成する

を自動で行う

## How to use

1. tailscaleのインストールとセットアップを行い、サーバを共有してもらう
2. `setup.bat`を実行  
  指示に従いMinecraftランチャーを閉じ、なんらかのキーを押す  
  しばらくするとFabricセットアップが開かれるので支持通りのバージョンを選択してインストール  
  起動構成が自動的に作成されるのでなんらかのキーを押してウィンドウ（:黒い画面）を閉じる  
3. Minecraftランチャーを起動し、作成された1.x.y_fabric_mc-ryodanという起動構成を起動して、サーバに接続する -> サーバアドレスは`mc-ryodan.tayra-buri.ts.net`
