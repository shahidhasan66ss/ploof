@ECHO OFF
SET DIRNAME=%~dp0
IF "%DIRNAME%" == "" SET DIRNAME=.
SET CLASSPATH=%DIRNAME%\gradle\wrapper\gradle-wrapper.jar
IF NOT EXIST "%CLASSPATH%" (
  ECHO Missing gradle-wrapper.jar. Run flutter create --platforms=android . once with a Flutter SDK.
  EXIT /B 1
)
"%JAVA_HOME%\bin\java.exe" -classpath "%CLASSPATH%" org.gradle.wrapper.GradleWrapperMain %*
