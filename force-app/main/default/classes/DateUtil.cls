public class DateUtil {
    @TestVisible
    private static Datetime now;

    @TestVisible
    private static Date today;

    public static Datetime now() {
        return now == null ? Datetime.now() : now;
    }

    public static Date today() {
        return today == null ? Date.today() : today;
    }
}
