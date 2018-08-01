forfiles /S /M *Azure*.config /C "cmd /c rename @file @fname.config.disabled"
forfiles /S /M *Lucene*.config.disabled /C "cmd /c rename @file @fname."