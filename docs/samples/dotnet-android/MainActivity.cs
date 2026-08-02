using Android.App;
using Android.OS;
using Android.Widget;

namespace SampleAndroidApp;

[Activity(Label = "@string/app_name", MainLauncher = true)]
public class MainActivity : Activity
{
    protected override void OnCreate(Bundle? savedInstanceState)
    {
        base.OnCreate(savedInstanceState);

        // 補完確認ポイント:
        //   - Android.* 名前空間の型（TextView, LinearLayout など）
        //   - this.（Activity のメンバー）
        //   - textView. のあとのメンバー補完
        var textView = new TextView(this)
        {
            Text = "Hello from .NET for Android",
            TextSize = 24,
        };

        var layout = new LinearLayout(this)
        {
            Orientation = Orientation.Vertical,
        };
        layout.AddView(textView);

        SetContentView(layout);
    }
}
