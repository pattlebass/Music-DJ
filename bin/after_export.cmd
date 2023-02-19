rmdir /s /q fin\
mkdir fin

:: Android
move android\MusicDJ_32bit.apk fin\MusicDJ_32bit.apk
move android\MusicDJ_64bit.apk fin\MusicDJ_64bit.apk
:: Windows
7z a fin/MusicDJ.Windows.zip ./win/*
:: Linux
7z a fin/MusicDJ.Linux.zip ./linux/*
:: HTML5
7z a fin/MusicDJ.HTML5.zip ./html5/*