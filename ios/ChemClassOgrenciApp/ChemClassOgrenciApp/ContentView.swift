import SwiftUI
import WebKit

// ← ChemClass Öğrenci canlı adresi (Cloudflare Worker)
private let kBaseURL = "https://chemclass-student.muratsunker.workers.dev"

// MARK: - SwiftUI bridge
struct ContentView: View {
    var body: some View {
        WebContainerView()
            .ignoresSafeArea()
    }
}

struct WebContainerView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> WebViewController { WebViewController() }
    func updateUIViewController(_ vc: WebViewController, context: Context) {}
}

// MARK: - Main controller
class WebViewController: UIViewController {

    private var webView: WKWebView!
    private var errorView: UIView!
    private var activityIndicator: UIActivityIndicatorView!
    private var refreshControl: UIRefreshControl!

    private let accentColor = UIColor(red: 0/255, green: 212/255, blue: 170/255, alpha: 1)
    private let bgColor     = UIColor(red: 10/255, green: 14/255, blue: 26/255, alpha: 1)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = bgColor
        setupWebView()
        setupErrorView()
        setupActivityIndicator()
        loadURL()
    }

    // MARK: - Setup

    private func setupWebView() {
        let prefs = WKWebpagePreferences()
        prefs.allowsContentJavaScript = true

        let config = WKWebViewConfiguration()
        config.defaultWebpagePreferences = prefs
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        config.allowsPictureInPictureMediaPlayback = true
        config.websiteDataStore = .default()

        webView = WKWebView(frame: .zero, configuration: config)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.allowsBackForwardNavigationGestures = false
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.isOpaque = false
        webView.backgroundColor = bgColor
        webView.scrollView.backgroundColor = bgColor

        refreshControl = UIRefreshControl()
        refreshControl.tintColor = accentColor
        refreshControl.addTarget(self, action: #selector(didPullToRefresh), for: .valueChanged)
        webView.scrollView.addSubview(refreshControl)

        view.addSubview(webView)
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupErrorView() {
        errorView = UIView()
        errorView.translatesAutoresizingMaskIntoConstraints = false
        errorView.backgroundColor = bgColor
        errorView.isHidden = true

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 14
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false

        let icon = UILabel()
        icon.text = "📡"
        icon.font = .systemFont(ofSize: 52)

        let title = UILabel()
        title.text = "Bağlantı Yok"
        title.textColor = .white
        title.font = .systemFont(ofSize: 20, weight: .semibold)

        let subtitle = UILabel()
        subtitle.text = "İnternet bağlantınızı kontrol edin\nve tekrar deneyin."
        subtitle.textColor = UIColor(white: 0.55, alpha: 1)
        subtitle.font = .systemFont(ofSize: 15)
        subtitle.textAlignment = .center
        subtitle.numberOfLines = 0

        let button = UIButton(type: .system)
        button.setTitle("  Tekrar Dene  ", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = accentColor
        button.layer.cornerRadius = 10
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        var cfg = UIButton.Configuration.filled()
        cfg.baseBackgroundColor = accentColor
        cfg.baseForegroundColor = .white
        cfg.cornerStyle = .medium
        cfg.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 28, bottom: 12, trailing: 28)
        button.configuration = cfg
        button.addTarget(self, action: #selector(didTapRetry), for: .touchUpInside)

        [icon, title, subtitle, button].forEach { stack.addArrangedSubview($0) }
        stack.setCustomSpacing(20, after: subtitle)

        errorView.addSubview(stack)
        view.addSubview(errorView)
        NSLayoutConstraint.activate([
            errorView.topAnchor.constraint(equalTo: view.topAnchor),
            errorView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            errorView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            errorView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            stack.centerXAnchor.constraint(equalTo: errorView.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: errorView.centerYAnchor)
        ])
    }

    private func setupActivityIndicator() {
        activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.color = accentColor
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.hidesWhenStopped = true
        view.addSubview(activityIndicator)
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    // MARK: - Load

    private func loadURL() {
        guard let url = URL(string: kBaseURL) else { return }
        let req = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 20)
        activityIndicator.startAnimating()
        webView.load(req)
    }

    @objc private func didPullToRefresh() { webView.reload() }

    @objc private func didTapRetry() {
        errorView.isHidden = true
        loadURL()
    }

    private func showError() {
        activityIndicator.stopAnimating()
        refreshControl.endRefreshing()
        errorView.isHidden = false
    }
}

// MARK: - WKNavigationDelegate
extension WebViewController: WKNavigationDelegate {

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        activityIndicator.stopAnimating()
        refreshControl.endRefreshing()
        errorView.isHidden = true
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        guard (error as NSError).code != NSURLErrorCancelled else { return }
        showError()
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        guard (error as NSError).code != NSURLErrorCancelled else { return }
        showError()
    }

    func webView(_ webView: WKWebView,
                 decidePolicyFor action: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = action.request.url, let host = url.host else {
            decisionHandler(.allow); return
        }
        let trusted = ["pages.dev", "supabase.co", "jsdelivr.net", "cdnjs.cloudflare.com",
                       "unpkg.com", "muratsunker"]
        let isTrusted = trusted.contains(where: { host.contains($0) })
        if !isTrusted && action.navigationType == .linkActivated {
            UIApplication.shared.open(url)
            decisionHandler(.cancel)
        } else {
            decisionHandler(.allow)
        }
    }
}

// MARK: - WKUIDelegate
extension WebViewController: WKUIDelegate {

    // JS alert()
    func webView(_ webView: WKWebView,
                 runJavaScriptAlertPanelWithMessage message: String,
                 initiatedByFrame frame: WKFrameInfo,
                 completionHandler: @escaping () -> Void) {
        let ac = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "Tamam", style: .default) { _ in completionHandler() })
        present(ac, animated: true)
    }

    // JS confirm()
    func webView(_ webView: WKWebView,
                 runJavaScriptConfirmPanelWithMessage message: String,
                 initiatedByFrame frame: WKFrameInfo,
                 completionHandler: @escaping (Bool) -> Void) {
        let ac = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "Tamam", style: .default) { _ in completionHandler(true) })
        ac.addAction(UIAlertAction(title: "İptal", style: .cancel) { _ in completionHandler(false) })
        present(ac, animated: true)
    }

    // JS prompt()
    func webView(_ webView: WKWebView,
                 runJavaScriptTextInputPanelWithPrompt prompt: String,
                 defaultText: String?,
                 initiatedByFrame frame: WKFrameInfo,
                 completionHandler: @escaping (String?) -> Void) {
        let ac = UIAlertController(title: nil, message: prompt, preferredStyle: .alert)
        ac.addTextField { tf in tf.text = defaultText }
        ac.addAction(UIAlertAction(title: "Tamam", style: .default) { _ in
            completionHandler(ac.textFields?.first?.text)
        })
        ac.addAction(UIAlertAction(title: "İptal", style: .cancel) { _ in completionHandler(nil) })
        present(ac, animated: true)
    }

    // target="_blank" links open inside the app
    func webView(_ webView: WKWebView,
                 createWebViewWith configuration: WKWebViewConfiguration,
                 for action: WKNavigationAction,
                 windowFeatures: WKWindowFeatures) -> WKWebView? {
        if action.targetFrame == nil { webView.load(action.request) }
        return nil
    }

    // Camera / mic permission for webRTC / getUserMedia
    @available(iOS 15.0, *)
    func webView(_ webView: WKWebView,
                 requestMediaCapturePermissionFor origin: WKSecurityOrigin,
                 initiatedByFrame frame: WKFrameInfo,
                 type: WKMediaCaptureType,
                 decisionHandler: @escaping (WKPermissionDecision) -> Void) {
        decisionHandler(.grant)
    }
}
