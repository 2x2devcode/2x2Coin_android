@HiltAndroidApp
class qtprojectCoin2X2Wallet : Application() {
    companion object {
        @SuppressLint("StaticFieldLeak")
        private lateinit var context: Context
    }

    override fun onCreate() {
        super.onCreate()
        context = applicationContext
    }
}
